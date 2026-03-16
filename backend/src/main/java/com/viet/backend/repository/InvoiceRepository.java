package com.viet.backend.repository;

import com.viet.backend.model.Invoice;
import com.viet.backend.model.Invoice.InvoiceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {

    Optional<Invoice> findByInvoiceCode(String invoiceCode);

    boolean existsByInvoiceCode(String invoiceCode);

    // Find all invoices for an apartment
    Page<Invoice> findByApartmentId(Long apartmentId, Pageable pageable);

    // Filter by status
    Page<Invoice> findByApartmentIdAndStatus(Long apartmentId,
                                             InvoiceStatus status,
                                             Pageable pageable);

    // Count by status for summary card
    long countByApartmentIdAndStatus(Long apartmentId, InvoiceStatus status);

    // Auto-mark overdue: UNPAID invoices past dueDate
    @Query("SELECT i FROM Invoice i WHERE i.status = 'UNPAID' AND i.dueDate < :now")
    List<Invoice> findOverdue(@Param("now") LocalDateTime now);

    // Manager: tất cả invoices (có filter status, search)
    @Query(value = """        
        SELECT DISTINCT a FROM Apartment a
        LEFT JOIN FETCH a.block
        LEFT JOIN FETCH a.resident r
        LEFT JOIN FETCH r.user
        WHERE EXISTS (SELECT i FROM Invoice i WHERE i.apartment = a)
          AND (:search IS NULL OR LOWER(a.apartmentCode) LIKE LOWER(CONCAT('%',:search,'%')))
        ORDER BY a.apartmentCode ASC
        """,
        countQuery = """        
        SELECT COUNT(DISTINCT a) FROM Apartment a
        WHERE EXISTS (SELECT i FROM Invoice i WHERE i.apartment = a)
          AND (:search IS NULL OR LOWER(a.apartmentCode) LIKE LOWER(CONCAT('%',:search,'%')))
        """)
    Page<com.viet.backend.model.Apartment> findApartmentsWithInvoices(
            @Param("search") String search,
            Pageable pageable);

    // Manager: invoices theo apartmentId (tất cả status)
    @Query("""        
        SELECT i FROM Invoice i
        LEFT JOIN FETCH i.apartment a
        LEFT JOIN FETCH a.block
        LEFT JOIN FETCH a.resident r
        LEFT JOIN FETCH r.user
        WHERE a.id = :apartmentId
        ORDER BY i.dueDate DESC
        """)
    List<Invoice> findAllByApartmentId(@Param("apartmentId") Long apartmentId);

    // Manager summary: tổng hợp số liệu toàn bộ
    @Query("SELECT COUNT(i) FROM Invoice i WHERE i.status = :status")
    long countByStatus(@Param("status") InvoiceStatus status);

    @Query("SELECT COALESCE(SUM(i.total),0) FROM Invoice i WHERE i.status IN ('UNPAID','OVERDUE')")
    java.math.BigDecimal sumAllOutstanding();

    // Total outstanding (UNPAID + OVERDUE) for a given apartment
    @Query("""
            SELECT COALESCE(SUM(i.total), 0)
            FROM Invoice i
            WHERE i.apartment.id = :apartmentId
              AND i.status IN ('UNPAID', 'OVERDUE')
            """)
    java.math.BigDecimal sumOutstanding(@Param("apartmentId") Long apartmentId);
}