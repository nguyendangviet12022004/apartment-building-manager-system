package com.viet.backend.controller;

import com.viet.backend.dto.RequestResponse;
import com.viet.backend.model.Request;
import com.viet.backend.service.RequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;

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

    @GetMapping("/my")
    public ResponseEntity<Page<RequestResponse>> getMyRequests(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String issueType,
            @RequestParam(required = false, defaultValue = "newest") String sort,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "20") int size) {
        return ResponseEntity.ok(requestService.getMyRequests(status, issueType, sort, page, size));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<RequestResponse> createResidentRequest(
            @RequestParam String title,
            @RequestParam String description,
            @RequestParam String issueType,
            @RequestParam String priority,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String occurrenceTime,
            @RequestPart(value = "files", required = false) List<MultipartFile> files) {
        return ResponseEntity.ok(requestService.createResidentRequest(title, description, issueType, priority, location, occurrenceTime, files));
    }

    @PostMapping(value = "/user/{userId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<RequestResponse> createRequest(
            @PathVariable Integer userId,
            @RequestParam String title,
            @RequestParam String description,
            @RequestPart(value = "files", required = false) List<MultipartFile> files) {
        return ResponseEntity.ok(requestService.createRequest(userId, title, description, files));
    }

    @PatchMapping("/{requestId}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<RequestResponse> updateStatus(
            @PathVariable Long requestId,
            @RequestHeader("X-User-ID") Integer adminId,
            @RequestParam Request.RequestStatus status,
            @RequestParam(required = false) String response) {
        return ResponseEntity.ok(requestService.updateStatus(requestId, adminId, status, response));
    }

    @PatchMapping("/{requestId}/timeline")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<RequestResponse> setTimeline(
            @PathVariable Long requestId,
            @RequestParam LocalDateTime solvedBy) {
        return ResponseEntity.ok(requestService.setTimeline(requestId, solvedBy));
    }
}
