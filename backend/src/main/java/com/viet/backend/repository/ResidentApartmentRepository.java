package com.viet.backend.repository;

import com.viet.backend.model.ResidentApartment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ResidentApartmentRepository extends JpaRepository<ResidentApartment, Long> {

    @EntityGraph(attributePaths = { "resident", "resident.user", "apartment" })
    List<ResidentApartment> findAllByApartmentId(Long apartmentId);

    @EntityGraph(attributePaths = { "apartment", "apartment.block" })
    List<ResidentApartment> findAllByResidentId(Long residentId);
}
