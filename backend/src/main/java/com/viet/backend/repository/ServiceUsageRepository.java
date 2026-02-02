package com.viet.backend.repository;

import com.viet.backend.model.ServiceUsage;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ServiceUsageRepository extends JpaRepository<ServiceUsage, Long> {

    @EntityGraph(attributePaths = { "apartment", "service" })
    List<ServiceUsage> findAllByApartmentId(Long apartmentId);

    @EntityGraph(attributePaths = { "apartment", "service" })
    List<ServiceUsage> findByRecordDateBetween(LocalDateTime start, LocalDateTime end);

    @EntityGraph(attributePaths = { "apartment", "service" })
    List<ServiceUsage> findAllByServiceIdAndRecordDateBetween(Long serviceId, LocalDateTime start, LocalDateTime end);
}
