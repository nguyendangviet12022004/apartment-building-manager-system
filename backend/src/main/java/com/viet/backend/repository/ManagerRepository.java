package com.viet.backend.repository;

import com.viet.backend.model.Manager;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ManagerRepository extends JpaRepository<Manager, Long> {

    @EntityGraph(attributePaths = { "user" })
    Optional<Manager> findWithUserByUserId(Integer userId);

    @EntityGraph(attributePaths = { "user" })
    List<Manager> findAllByDepartment(String department);
}
