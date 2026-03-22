package com.viet.backend.dto;

import com.viet.backend.model.PaymentTransaction;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

public class PaymentHistoryDTO {

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Item {
        private Long   id;
        private String txnRef;
        private String invoiceCode;
        private Long   invoiceId;
        private String invoiceMonth;   // "January 2026"
        private Long   amount;         // VND
        private PaymentTransaction.TxnStatus status;  // SUCCESS / FAILED / PENDING / CANCELLED
        private String bankCode;
        private String vnpayTransactionNo;
        private String vnpayResponseCode;
        private LocalDateTime createdAt;
        private LocalDateTime paidAt;
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Summary {
        private long totalTransactions;
        private long successCount;
        private long failedCount;
        private Long totalPaid; // tổng VND đã thanh toán thành công
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class PagedResponse {
        private List<Item>  content;
        private int         totalPages;
        private long        totalElements;
        private int         currentPage;
        private Summary     summary;
    }
}