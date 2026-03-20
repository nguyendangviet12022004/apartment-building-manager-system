package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "amenity_bookings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AmenityBooking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // bookingId

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "amenity_id", nullable = false)
    private Amenity amenity;

    @Column(nullable = false)
    private LocalDateTime startTime;

    @Column(nullable = false)
    private LocalDateTime endTime;

    @Enumerated(EnumType.STRING)
    private BookingStatus status; // BOOKED, USED, CANCELLED

    @Column(precision = 13, scale = 2)
    private BigDecimal totalPrice;

    private boolean isPaid;

    @Column(columnDefinition = "TEXT")
    private String note;

    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum BookingStatus {
        BOOKED, USED, CANCELLED
    }
}