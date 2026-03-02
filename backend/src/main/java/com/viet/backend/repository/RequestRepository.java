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

    @EntityGraph(attributePaths = { "user" })
    Page<Request> findByStatus(Request.RequestStatus status, Pageable pageable);
}
