package com.viet.backend.repository;

import com.viet.backend.model.Invoice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {

    @EntityGraph(attributePaths = { "apartment" })
    List<Invoice> findAllByApartmentId(Long apartmentId);

    @EntityGraph(attributePaths = { "apartment" })
    List<Invoice> findByStatus(Invoice.InvoiceStatus status);

    @EntityGraph(attributePaths = { "apartment" })
    List<Invoice> findAllByApartmentIdAndStatus(Long apartmentId, Invoice.InvoiceStatus status);
}
