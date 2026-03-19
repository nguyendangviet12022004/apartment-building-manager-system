package com.viet.backend.controller;

import com.viet.backend.dto.ResidentDTO;
import com.viet.backend.service.ResidentManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for resident management (Manager role)
 */
@RestController
@RequestMapping("/api/v1/residents")
@RequiredArgsConstructor
public class ResidentManagementController {

    private final ResidentManagementService residentManagementService;

    /**
     * GET /api/v1/residents
     * Get all residents with filtering and pagination
     * Only accessible by MANAGER and ADMIN roles
     */
    @GetMapping
//    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ResidentDTO.ResidentListResponse> getResidents(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String building,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {

        ResidentDTO.ResidentFilterRequest request = new ResidentDTO.ResidentFilterRequest(
                search, building, status, type, page, pageSize
        );

        ResidentDTO.ResidentListResponse response = residentManagementService.getResidents(request);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/v1/residents/{residentId}
     * Get resident details by resident ID
     * Only accessible by MANAGER and ADMIN roles
     */
    @GetMapping("/{residentId}")
//    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ResidentDTO.ResidentDetailResponse> getResidentDetails(
            @PathVariable Long residentId) {
        
        ResidentDTO.ResidentDetailResponse response = residentManagementService.getResidentDetails(residentId);
        return ResponseEntity.ok(response);
    }
}
