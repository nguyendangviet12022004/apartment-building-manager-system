package com.viet.backend.repository;

import com.viet.backend.model.Apartment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

@Repository
public interface ApartmentRepository extends JpaRepository<Apartment, Long>, JpaSpecificationExecutor<Apartment> {

    @EntityGraph(attributePaths = { "block" })
    Optional<Apartment> findWithBlockById(Long id);

    @EntityGraph(attributePaths = { "block" })
    List<Apartment> findAllByBlockId(Long blockId);

    @Query("SELECT a FROM Apartment a LEFT JOIN FETCH a.block WHERE a.apartmentCode = :code")
    Optional<Apartment> findByApartmentCodeWithBlock(@Param("code") String code);

    List<Apartment> findByStatus(String status);

    List<Apartment> findByResidentId(Long residentId);

    // Tìm apartment theo userId (User → Resident → Apartment)
    Optional<Apartment> findByResidentUserId(Integer userId);

    // Dùng cho ReminderService — fetch eager resident + user trong 1 query
    @Query("""        
        SELECT a FROM Apartment a
        LEFT JOIN FETCH a.block
        LEFT JOIN FETCH a.resident r
        LEFT JOIN FETCH r.user
        WHERE a.id = :id
        """)
    Optional<Apartment> findByIdWithResident(@Param("id") Long id);

    List<Apartment> findAll();

    List<Apartment> findByUsed(boolean used);

    @Query("""
        SELECT a FROM Apartment a
        LEFT JOIN FETCH a.block
        LEFT JOIN FETCH a.resident r
        LEFT JOIN FETCH r.user
        WHERE (:used IS NULL OR a.used = :used)
    """)
    List<Apartment> findAllWithDetails(@Param("used") Boolean used);

    Page<Apartment> findByBlockId(Long blockId, Pageable pageable);
}
