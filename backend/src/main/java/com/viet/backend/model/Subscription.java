package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "subscriptions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Subscription {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id")
    private Apartment apartment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id")
    private Service service;

    private LocalDateTime startDate;
    private LocalDateTime endDate;

    @Builder.Default
    private boolean autoRenew = true;

    private LocalDateTime cancelDate;

    @Enumerated(EnumType.STRING)
    private SubscriptionStatus status;

    public enum SubscriptionStatus {
        ACTIVE, CANCELLED, EXPIRED, PENDING
    }
}
