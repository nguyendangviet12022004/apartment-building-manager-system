package com.viet.backend.dto;

import com.viet.backend.model.Amenity;
import com.viet.backend.model.AmenityBooking.BookingStatus;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;

public class AmenityDTO {

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class AmenityResponse {
        private Integer id;
        private String name;
        private String type;
        private String description;
        private BigDecimal pricePerDuration;
        private Amenity.PricingType pricingType;
        private Integer capacity;
        private boolean requiresBooking;
        private boolean isAvailable;
        private LocalTime openTime;
        private LocalTime closeTime;
    }

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class BookingRequest {
        private Integer userId;
        private Integer amenityId;
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private String note;
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class BookingResponse {
        private Integer id;
        private Integer amenityId;
        private String amenityName;
        private Integer userId;
        private String userName; // Optional
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private BookingStatus status;
        private BigDecimal totalPrice;
        private boolean isPaid;
        private String note;
        private LocalDateTime createdAt;
    }

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class StatusUpdate {
        private BookingStatus status;
        private Boolean isPaid; // Optional update
    }
}