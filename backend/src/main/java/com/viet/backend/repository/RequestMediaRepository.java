package com.viet.backend.repository;

import com.viet.backend.model.RequestMedia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RequestMediaRepository extends JpaRepository<RequestMedia, Long> {
}
