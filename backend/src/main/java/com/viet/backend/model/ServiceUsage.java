package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "service_usage")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceUsage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id")
    private Apartment apartment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id")
    private Service service;

    private Double oldIndex;
    private Double newIndex;
    private Double usageAmount;
    private LocalDateTime recordDate;
}
