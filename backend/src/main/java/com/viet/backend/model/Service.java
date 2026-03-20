package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "services")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
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

    public enum ServiceType {
        METERED,   // điện, nước → quantity × unitPrice
        FIXED,     // quản lí, vệ sinh → unitPrice là tổng cố định
        PARKING,    // xe → quantity (số xe) × unitPrice
        AMENITY     // tiện ích khác → quantity × unitPrice
    }
}