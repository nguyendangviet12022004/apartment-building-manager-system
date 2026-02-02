package com.viet.backend.repository;

import com.viet.backend.model.Apartment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ApartmentRepository extends JpaRepository<Apartment, Long> {

    @EntityGraph(attributePaths = { "block" })
    Optional<Apartment> findWithBlockById(Long id);

    @EntityGraph(attributePaths = { "block" })
    List<Apartment> findAllByBlockId(Long blockId);

    @Query("SELECT a FROM Apartment a LEFT JOIN FETCH a.block WHERE a.apartmentCode = :code")
    Optional<Apartment> findByApartmentCodeWithBlock(@Param("code") String code);

    List<Apartment> findByStatus(String status);
}
