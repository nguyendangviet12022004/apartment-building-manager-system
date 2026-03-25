package com.viet.backend.service;

import com.viet.backend.dto.BlockRequest;
import com.viet.backend.model.Block;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.BlockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BlockService {

    private final BlockRepository blockRepository;
    private final ApartmentRepository apartmentRepository;

    @Transactional
    public Block createBlock(BlockRequest request) {
        String code = request.getBlockCode();
        if (code == null || code.length() != 3) {
            throw new RuntimeException("Block code must be exactly 3 characters for BR-01 compliance");
        }

        if (blockRepository.findByBlockCode(code).isPresent()) {
            throw new RuntimeException("Block code already exists: " + code);
        }

        Block block = Block.builder()
                .blockCode(request.getBlockCode())
                .description(request.getDescription())
                .build();

        return blockRepository.save(block);
    }

    @Transactional(readOnly = true)
    public List<Block> getAllBlocks() {
        return blockRepository.findAll();
    }

    @Transactional
    public Block updateBlock(Long id, BlockRequest request) {
        Block block = blockRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Block not found with id: " + id));

        String code = request.getBlockCode();
        if (code == null || code.length() != 3) {
            throw new RuntimeException("Block code must be exactly 3 characters for BR-01 compliance");
        }

        if (!block.getBlockCode().equals(code) && blockRepository.findByBlockCode(code).isPresent()) {
            throw new RuntimeException("Block code already exists: " + code);
        }

        block.setBlockCode(code);
        block.setDescription(request.getDescription());

        return blockRepository.save(block);
    }

    @Transactional
    public void deleteBlock(Long id) {
        if (!blockRepository.existsById(id)) {
            throw new RuntimeException("Block not found with id: " + id);
        }

        if (!apartmentRepository.findAllByBlockId(id).isEmpty()) {
            throw new RuntimeException("Cannot delete block: There are apartments associated with this block.");
        }

        blockRepository.deleteById(id);
    }
}
