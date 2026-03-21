package com.viet.backend.repository;

import com.viet.backend.model.Request;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface RequestRepository extends JpaRepository<Request, Long>, JpaSpecificationExecutor<Request> {

    @EntityGraph(attributePaths = { "user" })
    Page<Request> findAllByUserId(Integer userId, Pageable pageable);

    @org.springframework.data.jpa.repository.Query(
        "SELECT r FROM Request r WHERE r.user.id = :userId " +
        "AND (:status IS NULL OR r.status = :status) " +
        "AND (:issueType IS NULL OR r.issueType = :issueType)"
    )
    @EntityGraph(attributePaths = { "user" })
    Page<Request> findByUserIdWithFilters(
        @org.springframework.data.repository.query.Param("userId") Integer userId, 
        @org.springframework.data.repository.query.Param("status") Request.RequestStatus status, 
        @org.springframework.data.repository.query.Param("issueType") String issueType, 
        Pageable pageable);

    @EntityGraph(attributePaths = { "user" })
    Page<Request> findByStatus(Request.RequestStatus status, Pageable pageable);
}
