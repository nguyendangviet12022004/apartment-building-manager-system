package com.viet.backend.repository;

import com.viet.backend.model.Block;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BlockRepository extends JpaRepository<Block, Long> {
    Optional<Block> findByBlockCode(String blockCode);
}
