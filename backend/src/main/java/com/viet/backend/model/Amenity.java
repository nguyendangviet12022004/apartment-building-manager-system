package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalTime;

@Entity
@Table(name = "amenities")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Amenity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false)
    private String name;          // Ví dụ: Swimming Pool, Gym

    private String type;          // Sport, Relax, Service...

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(precision = 13, scale = 2)
    private BigDecimal pricePerDuration;  // phí sử dụng theo loại (giờ/ngày/tháng)

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private PricingType pricingType = PricingType.PER_HOUR;

    private Integer capacity;         // số người tối đa

    @Column(nullable = false)
    @Builder.Default
    private boolean requiresBooking = false; // có cần đặt trước không

    @Column(nullable = false)
    @Builder.Default
    private boolean isAvailable = true;     // trạng thái hoạt động

    private LocalTime openTime;
    private LocalTime closeTime;

    public enum PricingType {
        PER_HOUR,
        PER_DAY,
        PER_MONTH,
        FREE
    }
}