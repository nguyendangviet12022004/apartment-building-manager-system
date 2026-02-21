package com.viet.backend.repository;

import com.viet.backend.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByUserIdOrderByCreatedAtDesc(Integer userId);

    Page<Notification> findByUserId(Integer userId, Pageable pageable);

    List<Notification> findByUserIdAndIsReadFalse(Integer userId);

    long countByUserIdAndIsReadFalse(Integer userId);
}
