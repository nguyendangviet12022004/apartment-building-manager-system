package com.viet.backend.service;

import com.viet.backend.dto.BlockRequest;
import com.viet.backend.model.Block;
import com.viet.backend.repository.BlockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BlockService {

    private final BlockRepository blockRepository;

    @Transactional
    public Block createBlock(BlockRequest request) {
        if (blockRepository.findByBlockCode(request.getBlockCode()).isPresent()) {
            throw new RuntimeException("Block code already exists: " + request.getBlockCode());
        }

        Block block = Block.builder()
                .blockCode(request.getBlockCode())
                .description(request.getDescription())
                .build();

        return blockRepository.save(block);
    }
}
