package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * One line-item inside an Invoice.
 * e.g. "Electricity: 120 kWh × 3,500đ = 420,000đ"
 */
@Entity
@Table(name = "invoice_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InvoiceItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id", nullable = false)
    private Service service;

    // Snapshot tên & đơn vị tại thời điểm tạo (phòng trường hợp service bị sửa sau)
    @Column(nullable = false)
    private String serviceName;

    private String unit;

    // Số lượng sử dụng (kWh, m³, số xe...) — 0 nếu FIXED
    @Column(precision = 13, scale = 2)
    @Builder.Default
    private BigDecimal quantity = BigDecimal.ZERO;

    // Đơn giá tại thời điểm tạo (snapshot)
    @Column(precision = 13, scale = 2, nullable = false)
    private BigDecimal unitPrice;

    // Thành tiền = quantity × unitPrice (hoặc unitPrice nếu FIXED)
    @Column(precision = 13, scale = 2, nullable = false)
    private BigDecimal amount;
}