package com.viet.backend.repository;

import com.viet.backend.model.Resident;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ResidentRepository extends JpaRepository<Resident, Long> {

    @EntityGraph(attributePaths = { "user" })
    Optional<Resident> findWithUserByUserId(Integer userId);

    Optional<Resident> findByIdentityCard(String identityCard);
}
