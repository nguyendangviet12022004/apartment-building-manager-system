package com.viet.backend.service;

import com.viet.backend.dto.PaymentHistoryDTO;
import com.viet.backend.model.PaymentTransaction;
import com.viet.backend.repository.PaymentTransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PaymentHistoryService {

    private final PaymentTransactionRepository txnRepository;

    // ── Paginated history cho 1 apartment ────────────────────────────────────
    public PaymentHistoryDTO.PagedResponse getHistory(
            Long apartmentId, Pageable pageable) {

        Page<PaymentTransaction> page =
                txnRepository.findByApartmentIdPaged(apartmentId, pageable);

        // Summary từ toàn bộ (không phân trang)
        List<PaymentTransaction> all =
                txnRepository.findByApartmentId(apartmentId);

        long successCount = all.stream()
                .filter(t -> t.getStatus() == PaymentTransaction.TxnStatus.SUCCESS).count();
        long failedCount = all.stream()
                .filter(t -> t.getStatus() == PaymentTransaction.TxnStatus.FAILED).count();
        long totalPaid = all.stream()
                .filter(t -> t.getStatus() == PaymentTransaction.TxnStatus.SUCCESS)
                .mapToLong(t -> t.getAmount() != null ? t.getAmount() : 0L)
                .sum();

        PaymentHistoryDTO.Summary summary = PaymentHistoryDTO.Summary.builder()
                .totalTransactions(all.size())
                .successCount(successCount)
                .failedCount(failedCount)
                .totalPaid(totalPaid)
                .build();

        List<PaymentHistoryDTO.Item> items = page.getContent().stream()
                .map(this::toItem)
                .collect(Collectors.toList());

        return PaymentHistoryDTO.PagedResponse.builder()
                .content(items)
                .totalPages(page.getTotalPages())
                .totalElements(page.getTotalElements())
                .currentPage(page.getNumber())
                .summary(summary)
                .build();
    }

    // ── Chi tiết 1 giao dịch ──────────────────────────────────────────────────
    public PaymentHistoryDTO.Item getTransaction(Long txnId) {
        PaymentTransaction txn = txnRepository.findById(txnId)
                .orElseThrow(() -> new RuntimeException("Transaction not found: " + txnId));
        return toItem(txn);
    }

    // ── History theo invoiceId ────────────────────────────────────────────────
    public List<PaymentHistoryDTO.Item> getByInvoice(Long invoiceId) {
        return txnRepository.findByInvoiceId(invoiceId).stream()
                .map(this::toItem)
                .collect(Collectors.toList());
    }

    // ── Mapper ────────────────────────────────────────────────────────────────
    private PaymentHistoryDTO.Item toItem(PaymentTransaction t) {
        String invoiceMonth = "";
        String invoiceCode  = "";
        Long   invoiceId    = null;

        if (t.getInvoice() != null) {
            invoiceCode = t.getInvoice().getInvoiceCode();
            invoiceId   = t.getInvoice().getId();
            if (t.getInvoice().getInvoiceDate() != null) {
                invoiceMonth = t.getInvoice().getInvoiceDate()
                        .format(DateTimeFormatter.ofPattern("MMMM yyyy", Locale.ENGLISH));
            }
        }

        return PaymentHistoryDTO.Item.builder()
                .id(t.getId())
                .txnRef(t.getTxnRef())
                .invoiceCode(invoiceCode)
                .invoiceId(invoiceId)
                .invoiceMonth(invoiceMonth)
                .amount(t.getAmount())
                .status(t.getStatus())
                .bankCode(t.getBankCode())
                .vnpayTransactionNo(t.getTransactionNo())
                .vnpayResponseCode(t.getVnpResponseCode())
                .createdAt(t.getCreatedAt())
                .paidAt(t.getPaidAt())
                .build();
    }
}