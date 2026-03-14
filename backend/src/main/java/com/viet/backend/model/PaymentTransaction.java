package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Lưu lịch sử mỗi lần tạo giao dịch VNPAY
 */
@Entity
@Table(name = "payment_transactions")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class PaymentTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @Column(nullable = false, unique = true)
    private String txnRef;           // mã giao dịch gửi lên VNPAY (invoiceId_timestamp)

    private String transactionNo;    // mã GD phía VNPAY trả về sau khi thành công

    @Column(precision = 13, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private TxnStatus status = TxnStatus.PENDING;

    private String vnpResponseCode;  // "00" = thành công
    private String bankCode;
    private String cardType;

    private LocalDateTime createdAt;
    private LocalDateTime paidAt;

    public enum TxnStatus {
        PENDING, SUCCESS, FAILED, CANCELLED
    }
}