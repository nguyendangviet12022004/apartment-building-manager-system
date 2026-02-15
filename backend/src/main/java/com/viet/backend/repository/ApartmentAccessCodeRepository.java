package com.viet.backend.repository;

import com.viet.backend.model.ApartmentAccessCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApartmentAccessCodeRepository extends JpaRepository<ApartmentAccessCode, Long> {

    Optional<ApartmentAccessCode> findByCode(String code);

    @Modifying
    @Query("UPDATE ApartmentAccessCode a SET a.isActive = false WHERE a.apartment.id = :apartmentId AND a.isActive = true")
    void deactivateAllByApartmentId(Long apartmentId);

    Optional<ApartmentAccessCode> findByEmailAndApartment_IdAndIsActiveTrue(String email, Long apartmentId);
}
