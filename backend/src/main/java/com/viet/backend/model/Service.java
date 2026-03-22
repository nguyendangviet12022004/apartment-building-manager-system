package com.viet.backend.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalTime;

@Entity
@Table(name = "services")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Service {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String serviceName;       // e.g. "Electricity", "Water", "Management Fee"

    private String unit;              // e.g. "kWh", "m³", "month", "vehicle"

    @Column(precision = 13, scale = 2)
    private BigDecimal unitPrice;     // price per unit (VND)

    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ServiceType serviceType = ServiceType.METERED;

    // true  → manager inputs usage (quantity × unitPrice)
    // false → fixed amount per period regardless of usage
    @Column(nullable = false)
    @Builder.Default
    private boolean metered = true;

    @Column(nullable = false)
    @Builder.Default
    private boolean active = true;    // soft-delete / disable unused services

    @Column(nullable = false)
    @Builder.Default
    private Integer capacity = 1;     // Sức chứa tối đa cùng một thời điểm (VD: 1 sân tennis, 20 slot hồ bơi)

    @JsonFormat(pattern = "HH:mm:ss")
    private LocalTime openingTime;

    @JsonFormat(pattern = "HH:mm:ss")
    private LocalTime closingTime;

    public enum ServiceType {
        METERED,   // điện, nước → quantity × unitPrice
        FIXED,     // quản lí, vệ sinh → unitPrice là tổng cố định
        PARKING,    // xe → quantity (số xe) × unitPrice
        AMENITY     // tiện ích khác → quantity × unitPrice
    }
}