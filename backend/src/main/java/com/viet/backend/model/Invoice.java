package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

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

    @Column(nullable = false, unique = true)
    private String invoiceCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id")
    private Apartment apartment;

    @Column(precision = 13, scale = 2)
    private BigDecimal subtotal;    // tổng từ các InvoiceItem

    @Column(precision = 13, scale = 2)
    @Builder.Default
    private BigDecimal lateFee = BigDecimal.ZERO;

    @Column(precision = 13, scale = 2)
    private BigDecimal total;       // subtotal + lateFee

    private LocalDateTime invoiceDate;
    private LocalDateTime dueDate;
    @Column(name = "transaction_id")
    private String transactionId;
    private LocalDateTime createdAt;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private InvoiceStatus status = InvoiceStatus.UNPAID;

    // Cascade: khi save Invoice thì save luôn các items
    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<InvoiceItem> items = new ArrayList<>();

    public enum InvoiceStatus {
        UNPAID, PAID, OVERDUE, CANCELLED
    }
}