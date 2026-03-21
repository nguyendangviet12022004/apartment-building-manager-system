package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "service_bookings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceBooking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id", nullable = false)
    private Apartment apartment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id", nullable = false)
    private Service service;

    private LocalDateTime startTime;
    private LocalDateTime endTime;
    
    private String note; // Ghi chú thêm (VD: mang thêm ghế)

    @Enumerated(EnumType.STRING)
    private BookingStatus status;

    public enum BookingStatus {
        PENDING, CONFIRMED, REJECTED, CANCELLED, COMPLETED
    }
}