package com.viet.backend.controller;

import com.viet.backend.dto.ApartmentDTO;
import com.viet.backend.dto.ApartmentRequest;
import com.viet.backend.dto.ApartmentResponse;
import com.viet.backend.service.ApartmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
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
    public List<ApartmentDTO> getApartments(
            @RequestParam(required = false) Boolean used) {
        if (used != null) return apartmentService.getByUsed(used);
        return apartmentService.getAll();
    }

    // GET /api/v1/apartments/{id}
    @GetMapping("/{id}")
    public ApartmentDTO getById(@PathVariable Long id) {
        return apartmentService.getById(id);
    }
}
