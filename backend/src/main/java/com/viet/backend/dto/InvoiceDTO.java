package com.viet.backend.dto;

import com.viet.backend.model.Invoice.InvoiceStatus;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class InvoiceDTO {

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Response {
        private Long id;
        private String invoiceCode;
        private Long apartmentId;
        private String apartmentCode;
        private BigDecimal subtotal;
        private BigDecimal lateFee;
        private BigDecimal total;
        private LocalDateTime invoiceDate;
        private LocalDateTime dueDate;
        private LocalDateTime createdAt;
        private InvoiceStatus status;
        private long daysUntilDue;
        private List<ItemResponse> items;
        private List<String> serviceLabels;
        // Apartment detail (cho invoice detail screen)
        private Integer apartmentFloor;
        private Double apartmentArea;
        private String blockCode;
        private String residentName;
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class ItemResponse {
        private Long serviceId;
        private String serviceName;
        private String unit;
        private BigDecimal quantity;
        private BigDecimal unitPrice;
        private BigDecimal amount;
    }

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class Request {
        private Long apartmentId;
        private String invoiceCode;
        private LocalDateTime invoiceDate;
        private LocalDateTime dueDate;
        private BigDecimal lateFee;
        private InvoiceStatus status;
        private List<ItemRequest> items;
    }

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class ItemRequest {
        private Long serviceId;
        private BigDecimal quantity; // null/0 for FIXED services
    }

    // Manager invoice list item — mỗi dòng là 1 apartment với debt summary
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class ManagerListItem {
        private Long apartmentId;
        private String apartmentCode;
        private String blockCode;
        private Integer floor;
        private String residentName;
        private String residentEmail;
        private java.math.BigDecimal totalDebt;   // tổng UNPAID+OVERDUE
        private long unpaidCount;
        private long overdueCount;
        private int monthsOverdue;                // tháng overdue lâu nhất
        private String status;                    // "paid" | "unpaid" | "overdue"
        private String initials;                  // 2 chữ cái đầu tên
    }

    // Manager detail: thông tin apartment + danh sách invoices
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class ManagerDetail {
        private Long apartmentId;
        private String apartmentCode;
        private String blockCode;
        private Integer floor;
        private Double area;
        private String residentName;
        private String residentEmail;
        private String residentPhone;
        private String contractStart;
        private String contractEnd;
        private java.math.BigDecimal totalOutstanding;
        private List<Response> outstandingInvoices;
        private List<Response> paidInvoices;
    }

    // Manager global summary
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class ManagerSummary {
        private long totalApartments;
        private long overdueCount;
        private long unpaidCount;
        private java.math.BigDecimal totalOutstanding;
    }

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class StatusUpdate {
        private InvoiceStatus status;
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Summary {
        private long unpaidCount;
        private long paidCount;
        private long overdueCount;
        private BigDecimal totalOutstanding;
    }
}