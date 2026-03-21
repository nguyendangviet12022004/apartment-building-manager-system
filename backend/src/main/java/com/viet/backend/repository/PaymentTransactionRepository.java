package com.viet.backend.repository;

import com.viet.backend.model.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {

    Optional<PaymentTransaction> findByTxnRef(String txnRef);

    List<PaymentTransaction> findByInvoiceId(Long invoiceId);

    // Lấy tất cả lịch sử thanh toán của 1 apartment (qua invoice)
    @org.springframework.data.jpa.repository.Query("""        
        SELECT t FROM PaymentTransaction t
        JOIN FETCH t.invoice i
        JOIN FETCH i.apartment a
        WHERE a.id = :apartmentId
        ORDER BY t.createdAt DESC
        """)
    List<PaymentTransaction> findByApartmentId(
            @org.springframework.data.repository.query.Param("apartmentId") Long apartmentId);

    // Paginated version
    @org.springframework.data.jpa.repository.Query("""        
        SELECT t FROM PaymentTransaction t
        JOIN t.invoice i
        JOIN i.apartment a
        WHERE a.id = :apartmentId
        ORDER BY t.createdAt DESC
        """)
    org.springframework.data.domain.Page<PaymentTransaction> findByApartmentIdPaged(
            @org.springframework.data.repository.query.Param("apartmentId") Long apartmentId,
            org.springframework.data.domain.Pageable pageable);
}