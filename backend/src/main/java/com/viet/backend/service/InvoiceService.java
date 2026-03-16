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

    public InvoiceDTO.Response getByCode(String invoiceCode) {
        Invoice inv = invoiceRepository.findByInvoiceCode(invoiceCode)
                .orElseThrow(() -> new RuntimeException("Invoice not found: " + invoiceCode));
        return toResponse(inv);
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
    // Overload cho VNPay callback (nhận String thay vì DTO)
    public void updateStatus(long id, String statusStr) {
        var req = new InvoiceDTO.StatusUpdate();
        req.setStatus(InvoiceStatus.valueOf(statusStr));
        updateStatus((Long) id, req);
    }

    public InvoiceDTO.Response updateStatus(Long id, InvoiceDTO.StatusUpdate req) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Invoice not found: " + id));
        inv.setStatus(req.getStatus());
        return toResponse(invoiceRepository.save(inv));
    }

    public void delete(Long id) {
        invoiceRepository.deleteById(id);
    }

    // ── Manager: list apartments with debt summary ───────────────────────────
    public org.springframework.data.domain.Page<InvoiceDTO.ManagerListItem> managerList(
            String statusFilter, String search, Pageable pageable) {

        boolean hasDebt  = "hasdebt".equalsIgnoreCase(statusFilter);
        boolean onlyOver = "overdue".equalsIgnoreCase(statusFilter);
        boolean onlyUnpaid = "unpaid".equalsIgnoreCase(statusFilter);
        boolean onlyPaid = "paid".equalsIgnoreCase(statusFilter);

        // Query DISTINCT apartments (không bị duplicate)
        org.springframework.data.domain.Page<com.viet.backend.model.Apartment> aptPage =
                invoiceRepository.findApartmentsWithInvoices(
                        (search == null || search.isBlank()) ? null : search,
                        pageable);

        return aptPage.map(apt -> {
            long unpaid  = invoiceRepository.countByApartmentIdAndStatus(apt.getId(), InvoiceStatus.UNPAID);
            long overdue = invoiceRepository.countByApartmentIdAndStatus(apt.getId(), InvoiceStatus.OVERDUE);
            BigDecimal debt = invoiceRepository.sumOutstanding(apt.getId());
            if (debt == null) debt = BigDecimal.ZERO;

            // Áp dụng filter sau khi tính toán
            if (hasDebt   && debt.compareTo(BigDecimal.ZERO) == 0) return null;
            if (onlyOver  && overdue == 0)  return null;
            if (onlyUnpaid&& unpaid  == 0)  return null;
            if (onlyPaid  && (unpaid > 0 || overdue > 0)) return null;

            int maxMonths = invoiceRepository.findAllByApartmentId(apt.getId()).stream()
                    .filter(i -> i.getStatus() == InvoiceStatus.OVERDUE && i.getDueDate() != null)
                    .mapToInt(i -> (int) java.time.temporal.ChronoUnit.MONTHS.between(
                            i.getDueDate(), LocalDateTime.now()))
                    .max().orElse(0);

            String invStatus = overdue > 0 ? "overdue" : unpaid > 0 ? "unpaid" : "paid";

            String name = "", email = "";
            if (apt.getResident() != null && apt.getResident().getUser() != null) {
                var u = apt.getResident().getUser();
                name  = u.getFirstname() + " " + u.getLastname();
                email = u.getEmail() != null ? u.getEmail() : "";
            }
            String initials = name.length() >= 2
                    ? (name.substring(0, 1) + name.substring(name.lastIndexOf(' ') + 1, name.lastIndexOf(' ') + 2)).toUpperCase()
                    : name.length() > 0 ? name.substring(0, 1).toUpperCase() : "?";

            return InvoiceDTO.ManagerListItem.builder()
                    .apartmentId(apt.getId())
                    .apartmentCode(apt.getApartmentCode())
                    .blockCode(apt.getBlock() != null ? apt.getBlock().getBlockCode() : null)
                    .floor(apt.getFloor())
                    .residentName(name)
                    .residentEmail(email)
                    .totalDebt(debt)
                    .unpaidCount(unpaid)
                    .overdueCount(overdue)
                    .monthsOverdue(maxMonths)
                    .status(invStatus)
                    .initials(initials)
                    .build();
        });
    }

    // ── Manager: detail 1 apartment ──────────────────────────────────────────
    public InvoiceDTO.ManagerDetail managerDetail(Long apartmentId) {
        var apt = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found: " + apartmentId));

        List<Invoice> all = invoiceRepository.findAllByApartmentId(apartmentId);
        List<InvoiceDTO.Response> outstanding = all.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.UNPAID
                        || i.getStatus() == InvoiceStatus.OVERDUE)
                .map(this::toResponse).collect(Collectors.toList());
        List<InvoiceDTO.Response> paid = all.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PAID)
                .map(this::toResponse).collect(Collectors.toList());

        BigDecimal debt = invoiceRepository.sumOutstanding(apartmentId);

        String name = "", email = "", phone = "";
        if (apt.getResident() != null && apt.getResident().getUser() != null) {
            var u = apt.getResident().getUser();
            name  = u.getFirstname() + " " + u.getLastname();
            email = u.getEmail() != null ? u.getEmail() : "";
            // phone field nếu có trong User entity
        }

        return InvoiceDTO.ManagerDetail.builder()
                .apartmentId(apt.getId())
                .apartmentCode(apt.getApartmentCode())
                .blockCode(apt.getBlock() != null ? apt.getBlock().getBlockCode() : null)
                .floor(apt.getFloor())
                .area(apt.getArea())
                .residentName(name)
                .residentEmail(email)
                .residentPhone(phone)
                .totalOutstanding(debt != null ? debt : BigDecimal.ZERO)
                .outstandingInvoices(outstanding)
                .paidInvoices(paid)
                .build();
    }

    // ── Manager: global summary ───────────────────────────────────────────────
    public InvoiceDTO.ManagerSummary managerSummary() {
        long overdue = invoiceRepository.countByStatus(InvoiceStatus.OVERDUE);
        long unpaid  = invoiceRepository.countByStatus(InvoiceStatus.UNPAID);
        long total   = apartmentRepository.count();
        BigDecimal outstanding = invoiceRepository.sumAllOutstanding();
        return InvoiceDTO.ManagerSummary.builder()
                .totalApartments(total)
                .overdueCount(overdue)
                .unpaidCount(unpaid)
                .totalOutstanding(outstanding != null ? outstanding : BigDecimal.ZERO)
                .build();
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

        // Apartment detail
        Integer aptFloor = null;
        Double  aptArea  = null;
        String  blockCode = null;
        String  residentName = null;
        if (inv.getApartment() != null) {
            var apt = inv.getApartment();
            aptFloor = apt.getFloor();
            aptArea  = apt.getArea();
            if (apt.getBlock() != null)    blockCode    = apt.getBlock().getBlockCode();
            if (apt.getResident() != null && apt.getResident().getUser() != null) {
                var u = apt.getResident().getUser();
                residentName = u.getFirstname() + " " + u.getLastname();
            }
        }

        return InvoiceDTO.Response.builder()
                .id(inv.getId())
                .invoiceCode(inv.getInvoiceCode())
                .apartmentId(inv.getApartment() != null ? inv.getApartment().getId() : null)
                .apartmentCode(inv.getApartment() != null ? inv.getApartment().getApartmentCode() : null)
                .apartmentFloor(aptFloor)
                .apartmentArea(aptArea)
                .blockCode(blockCode)
                .residentName(residentName)
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