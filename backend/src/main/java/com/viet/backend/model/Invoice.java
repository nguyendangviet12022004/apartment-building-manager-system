package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "invoices")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Invoice {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id")
    private Apartment apartment;

    @Column(precision = 13, scale = 2)
    private BigDecimal amount;

    private LocalDateTime createdAt;

    @Enumerated(EnumType.STRING)
    private InvoiceStatus status;

    public enum InvoiceStatus {
        PAID, UNPAID, OVERDUE, CANCELLED
    }
}
