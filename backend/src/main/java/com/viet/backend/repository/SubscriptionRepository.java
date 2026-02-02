package com.viet.backend.repository;

import com.viet.backend.model.Subscription;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    @EntityGraph(attributePaths = { "apartment", "service" })
    List<Subscription> findAllByApartmentId(Long apartmentId);

    @EntityGraph(attributePaths = { "apartment", "service" })
    @Query("SELECT s FROM Subscription s WHERE s.status = :status AND s.endDate <= :now")
    List<Subscription> findExpiredSubscriptions(@Param("status") Subscription.SubscriptionStatus status,
            @Param("now") LocalDateTime now);

    @EntityGraph(attributePaths = { "apartment", "service" })
    List<Subscription> findByStatus(Subscription.SubscriptionStatus status);

    @EntityGraph(attributePaths = { "apartment", "service" })
    @Query("SELECT s FROM Subscription s WHERE s.autoRenew = true AND s.endDate BETWEEN :start AND :end")
    List<Subscription> findSubscriptionsToRenew(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
}
