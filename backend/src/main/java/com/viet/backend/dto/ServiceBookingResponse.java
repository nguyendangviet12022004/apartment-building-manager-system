package com.viet.backend.dto;

import com.viet.backend.model.ServiceBooking.BookingStatus;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class ServiceBookingResponse {
    private Long id;
    private Long serviceId;
    private String serviceName;
    private Long apartmentId;
    private String apartmentCode;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Integer quantity;
    private BigDecimal totalPrice;
    private String note;
    private BookingStatus status;
}