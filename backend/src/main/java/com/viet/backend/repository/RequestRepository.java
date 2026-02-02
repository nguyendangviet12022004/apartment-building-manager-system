package com.viet.backend.repository;

import com.viet.backend.model.Request;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RequestRepository extends JpaRepository<Request, Long> {

    @EntityGraph(attributePaths = { "user" })
    List<Request> findAllByUserId(Integer userId);

    @EntityGraph(attributePaths = { "user" })
    List<Request> findByStatus(Request.RequestStatus status);
}
