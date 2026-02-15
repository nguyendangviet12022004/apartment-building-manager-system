package com.viet.backend.repository;

import com.viet.backend.model.Resident;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ResidentRepository extends JpaRepository<Resident, Long> {

    @EntityGraph(attributePaths = { "user" })
    @org.springframework.data.jpa.repository.Query("SELECT r FROM Resident r WHERE r.user.id = :userId")
    Optional<Resident> findByUserId(@org.springframework.data.repository.query.Param("userId") Integer userId);

    Optional<Resident> findByIdentityCard(String identityCard);
}
