package com.viet.backend.service;

import com.viet.backend.dto.InvoiceDTO;
import com.viet.backend.model.*;
import com.viet.backend.model.Invoice.InvoiceStatus;
import com.viet.backend.model.Service.ServiceType;
import com.viet.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final ApartmentRepository apartmentRepository;
    private final ServiceRepository serviceRepository;

    public InvoiceDTO.Summary getSummary(Long apartmentId) {
        long unpaid  = invoiceRepository.countByApartmentIdAndStatus(apartmentId, InvoiceStatus.UNPAID);
        long paid    = invoiceRepository.countByApartmentIdAndStatus(apartmentId, InvoiceStatus.PAID);
        long overdue = invoiceRepository.countByApartmentIdAndStatus(apartmentId, InvoiceStatus.OVERDUE);
        BigDecimal outstanding = invoiceRepository.sumOutstanding(apartmentId);
        return InvoiceDTO.Summary.builder()
                .unpaidCount(unpaid).paidCount(paid).overdueCount(overdue)
                .totalOutstanding(outstanding != null ? outstanding : BigDecimal.ZERO)
                .build();
    }

    public Page<InvoiceDTO.Response> list(Long apartmentId, InvoiceStatus status, Pageable pageable) {
        Page<Invoice> page = status != null
                ? invoiceRepository.findByApartmentIdAndStatus(apartmentId, status, pageable)
                : invoiceRepository.findByApartmentId(apartmentId, pageable);
        return page.map(this::toResponse);
    }

    public InvoiceDTO.Response getById(Long id) {
        return toResponse(invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Invoice not found: " + id)));
    }

    @Transactional
    public InvoiceDTO.Response create(InvoiceDTO.Request req) {
        Apartment apartment = apartmentRepository.findById(req.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found: " + req.getApartmentId()));

        List<InvoiceItem> items = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO;

        for (InvoiceDTO.ItemRequest itemReq : req.getItems()) {
            com.viet.backend.model.Service svc = serviceRepository.findById(itemReq.getServiceId())
                    .orElseThrow(() -> new RuntimeException("Service not found: " + itemReq.getServiceId()));

            BigDecimal quantity;
            BigDecimal amount;

            if (svc.getServiceType() == ServiceType.FIXED) {
                quantity = BigDecimal.ONE;
                amount   = svc.getUnitPrice();
            } else {
                quantity = itemReq.getQuantity() != null ? itemReq.getQuantity() : BigDecimal.ZERO;
                amount   = quantity.multiply(svc.getUnitPrice());
            }

            items.add(InvoiceItem.builder()
                    .serviceName(svc.getServiceName())
                    .unit(svc.getUnit())
                    .quantity(quantity)
                    .unitPrice(svc.getUnitPrice())
                    .amount(amount)
                    .service(svc)
                    .build());

            subtotal = subtotal.add(amount);
        }

        BigDecimal lateFee = req.getLateFee() != null ? req.getLateFee() : BigDecimal.ZERO;
        String code = (req.getInvoiceCode() != null && !req.getInvoiceCode().isBlank())
                ? req.getInvoiceCode()
                : "INV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Invoice invoice = Invoice.builder()
                .invoiceCode(code)
                .apartment(apartment)
                .subtotal(subtotal)
                .lateFee(lateFee)
                .total(subtotal.add(lateFee))
                .invoiceDate(req.getInvoiceDate() != null ? req.getInvoiceDate() : LocalDateTime.now())
                .dueDate(req.getDueDate())
                .createdAt(LocalDateTime.now())
                .status(req.getStatus() != null ? req.getStatus() : InvoiceStatus.UNPAID)
                .build();

        // Link items after invoice is constructed
        items.forEach(item -> item.setInvoice(invoice));
        invoice.setItems(items);

        return toResponse(invoiceRepository.save(invoice));
    }

    @Transactional
    public InvoiceDTO.Response updateStatus(Long id, InvoiceDTO.StatusUpdate req) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Invoice not found: " + id));
        inv.setStatus(req.getStatus());
        return toResponse(invoiceRepository.save(inv));
    }

    public void delete(Long id) {
        invoiceRepository.deleteById(id);
    }

    @Scheduled(cron = "0 0 1 * * *")
    @Transactional
    public void markOverdue() {
        invoiceRepository.findOverdue(LocalDateTime.now())
                .forEach(inv -> inv.setStatus(InvoiceStatus.OVERDUE));
    }

    private InvoiceDTO.Response toResponse(Invoice inv) {
        long days = inv.getDueDate() != null
                ? ChronoUnit.DAYS.between(LocalDateTime.now(), inv.getDueDate())
                : 0;

        List<InvoiceDTO.ItemResponse> itemResponses = inv.getItems().stream()
                .map(item -> InvoiceDTO.ItemResponse.builder()
                        .serviceId(item.getService() != null ? item.getService().getId() : null)
                        .serviceName(item.getServiceName())
                        .unit(item.getUnit())
                        .quantity(item.getQuantity())
                        .unitPrice(item.getUnitPrice())
                        .amount(item.getAmount())
                        .build())
                .collect(Collectors.toList());

        // "Electricity: 120 kWh", "Management Fee", "Water: 8 m³"
        List<String> labels = inv.getItems().stream()
                .map(item -> {
                    if (item.getUnit() != null && item.getQuantity() != null
                            && item.getQuantity().compareTo(BigDecimal.ONE) != 0) {
                        return item.getServiceName() + ": "
                                + item.getQuantity().stripTrailingZeros().toPlainString()
                                + " " + item.getUnit();
                    }
                    return item.getServiceName();
                })
                .collect(Collectors.toList());

        return InvoiceDTO.Response.builder()
                .id(inv.getId())
                .invoiceCode(inv.getInvoiceCode())
                .apartmentId(inv.getApartment() != null ? inv.getApartment().getId() : null)
                .apartmentCode(inv.getApartment() != null ? inv.getApartment().getApartmentCode() : null)
                .subtotal(inv.getSubtotal())
                .lateFee(inv.getLateFee())
                .total(inv.getTotal())
                .invoiceDate(inv.getInvoiceDate())
                .dueDate(inv.getDueDate())
                .createdAt(inv.getCreatedAt())
                .status(inv.getStatus())
                .daysUntilDue(days)
                .items(itemResponses)
                .serviceLabels(labels)
                .build();
    }
}