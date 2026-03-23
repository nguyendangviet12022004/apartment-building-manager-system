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
     * Request DTO for calendar bookings
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BookingCalendarRequest {
        private String date;        // Format: yyyy-MM-dd (for day view)
        private String startDate;   // Format: yyyy-MM-dd (for week/month view)
        private String endDate;     // Format: yyyy-MM-dd (for week/month view)
        private String viewType;    // DAY, WEEK, MONTH
    }

    /**
     * Response DTO for calendar booking item
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CalendarBookingItem {
        private Long bookingId;
        private String serviceName;
        private String serviceIcon;
        private String apartmentCode;
        private String residentName;
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private String timeSlot;    // e.g., "09:00 - 11:00 AM"
        private String status;
    }

    /**
     * Response DTO for calendar view
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BookingCalendarResponse {
        private List<CalendarBookingItem> bookings;
        private int totalScheduled;
        private String currentDate;
        private String viewType;
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
