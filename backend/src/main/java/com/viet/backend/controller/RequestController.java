package com.viet.backend.controller;

import com.viet.backend.dto.RequestResponse;
import com.viet.backend.model.Request;
import com.viet.backend.service.RequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/requests")
@RequiredArgsConstructor
public class RequestController {

    private final RequestService requestService;

    @GetMapping("/admin")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<Page<RequestResponse>> getAllRequests(
            @RequestParam(required = false) Request.RequestStatus status,
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(requestService.getAllRequests(status, pageable));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<RequestResponse>> getUserRequests(
            @PathVariable Integer userId,
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(requestService.getUserRequests(userId, pageable));
    }

    @PostMapping("/user/{userId}")
    public ResponseEntity<RequestResponse> createRequest(
            @PathVariable Integer userId,
            @RequestParam String title,
            @RequestParam String description) {
        return ResponseEntity.ok(requestService.createRequest(userId, title, description));
    }

    @PatchMapping("/{requestId}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<RequestResponse> updateStatus(
            @PathVariable Long requestId,
            @RequestParam Request.RequestStatus status,
            @RequestParam(required = false) String response) {
        return ResponseEntity.ok(requestService.updateStatus(requestId, status, response));
    }
}
