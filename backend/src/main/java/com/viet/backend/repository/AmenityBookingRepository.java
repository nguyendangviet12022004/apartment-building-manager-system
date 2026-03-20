package com.viet.backend.repository;

import com.viet.backend.model.AmenityBooking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AmenityBookingRepository extends JpaRepository<AmenityBooking, Integer> {

    List<AmenityBooking> findByUserIdOrderByCreatedAtDesc(Integer userId);

    // Check if any booking overlaps with the requested time range for the given amenity.
    // Overlap logic: (StartA < EndB) and (EndA > StartB)
    @Query("SELECT COUNT(b) > 0 FROM AmenityBooking b " +
           "WHERE b.amenity.id = :amenityId " +
           "AND (b.startTime < :endTime AND b.endTime > :startTime)")
    boolean existsByAmenityIdAndOverlap(@Param("amenityId") Integer amenityId,
                                        @Param("startTime") LocalDateTime startTime,
                                        @Param("endTime") LocalDateTime endTime);
}