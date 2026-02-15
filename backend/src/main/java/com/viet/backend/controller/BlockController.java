package com.viet.backend.controller;

import com.viet.backend.dto.BlockRequest;
import com.viet.backend.model.Block;
import com.viet.backend.service.BlockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/blocks")
@RequiredArgsConstructor
public class BlockController {

    private final BlockService blockService;

    @PostMapping
    public ResponseEntity<Block> createBlock(@Valid @RequestBody BlockRequest request) {
        return ResponseEntity.ok(blockService.createBlock(request));
    }
}
