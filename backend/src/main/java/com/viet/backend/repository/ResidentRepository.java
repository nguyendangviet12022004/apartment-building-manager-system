package com.viet.backend.repository;

import com.viet.backend.model.Resident;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ResidentRepository extends JpaRepository<Resident, Long> {

    @EntityGraph(attributePaths = { "user" })
    @Query("SELECT r FROM Resident r WHERE r.user.id = :userId")
    Optional<Resident> findByUserId(@Param("userId") Integer userId);

    Optional<Resident> findByIdentityCard(String identityCard);

    // Thêm method này để fetch user cùng lúc, tránh LazyLoading
    @Query("SELECT r FROM Resident r LEFT JOIN FETCH r.user u ORDER BY u.firstname ASC")
    List<Resident> findAllWithUser();
}