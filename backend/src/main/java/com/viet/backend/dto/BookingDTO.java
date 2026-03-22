package com.viet.backend.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class BookingDTO {

    /**
     * Response DTO for booking list item
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BookingListItem {
        private Long bookingId;
        private String residentName;
        private String unitNumber;
        private String serviceName;
        private String serviceIcon;  // Icon identifier for frontend
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private String status;  // PENDING, CONFIRMED, REJECTED, CANCELLED, COMPLETED
        private BigDecimal totalPrice;
        private Integer quantity;
    }

    /**
     * Response DTO for paginated booking list
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BookingListResponse {
        private List<BookingListItem> bookings;
        private int totalCount;
        private int page;
        private int pageSize;
        private int totalPages;
    }

    /**
     * Request DTO for filtering bookings
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BookingFilterRequest {
        private String search;      // Search by resident name or unit
        private String status;      // Filter by status
        private Integer page;
        private Integer pageSize;
    }

    /**
     * Response DTO for booking details
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BookingDetailResponse {
        private Long bookingId;
        
        // Resident info
        private String residentName;
        private String residentPhone;
        private String residentEmail;
        private String unitNumber;
        
        // Service info
        private Long serviceId;
        private String serviceName;
        private String serviceDescription;
        private BigDecimal unitPrice;
        
        // Booking info
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private Integer quantity;
        private BigDecimal totalPrice;
        private String note;
        private String status;
        
        // Timestamps
        private LocalDateTime createdAt;
    }
}
