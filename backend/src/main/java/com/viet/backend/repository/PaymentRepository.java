package com.viet.backend.repository;

import com.viet.backend.model.Payment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    @EntityGraph(attributePaths = { "invoice", "invoice.apartment" })
    Optional<Payment> findWithInvoiceById(Long id);

    @EntityGraph(attributePaths = { "invoice" })
    List<Payment> findAllByInvoiceId(Long invoiceId);
}
