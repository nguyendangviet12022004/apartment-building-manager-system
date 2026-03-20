package com.viet.backend.controller;

import com.viet.backend.dto.ApartmentDTO;
import com.viet.backend.dto.ApartmentRequest;
import com.viet.backend.dto.ApartmentResponse;
import com.viet.backend.service.ApartmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/api/v1/apartments")
@RequiredArgsConstructor
public class ApartmentController {

    private final ApartmentService apartmentService;

    @PostMapping
    @PreAuthorize("hasAnyAuthority('MANAGER', 'ROLE_MANAGER', 'ADMIN', 'ROLE_ADMIN')")
    public ResponseEntity<ApartmentResponse> createApartment(@Valid @RequestBody ApartmentRequest request) {
        return ResponseEntity.ok(apartmentService.createApartment(request));
    }

    @GetMapping("/my")
    public ResponseEntity<?> getMyApartment(@RequestParam Integer userId) {
        return apartmentService.findApartmentIdByUserId(userId)
                .map(id -> ResponseEntity.ok(Map.of("apartmentId", id)))
                .orElse(ResponseEntity.notFound().build());
    }
    @GetMapping
    public ResponseEntity<?> getApartments(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long blockId,
            @RequestParam(required = false) Integer floor,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Boolean used,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {

        if (used != null && page == null && size == null) {
            return ResponseEntity.ok(apartmentService.getByUsed(used));
        }

        if (page == null && size == null && keyword == null && blockId == null && floor == null && status == null) {
            return ResponseEntity.ok(apartmentService.getAll());
        }

        org.springframework.data.domain.Pageable pageable = 
            org.springframework.data.domain.PageRequest.of(page != null ? page : 0, size != null ? size : 10);

        return ResponseEntity.ok(apartmentService.getApartments(keyword, blockId, floor, status, pageable));
    }

    // GET /api/v1/apartments/{id}
    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(apartmentService.getById(id));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", "Apartment not found"));
        }
    }
}
