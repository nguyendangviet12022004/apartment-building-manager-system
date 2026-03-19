package com.viet.backend.controller;

import com.viet.backend.dto.ProfileDTO;
import com.viet.backend.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    /**
     * GET /api/v1/profile/{userId}
     * UC-06 Step 3 – fetch full profile data.
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ProfileDTO.Response> getProfile(
            @PathVariable Integer userId) {
        return ResponseEntity.ok(profileService.getProfile(userId));
    }

    /**
     * PUT /api/v1/profile/{userId}
     * UC-07 – update personal info from Edit Profile screen.
     */
    @PutMapping("/{userId}")
    public ResponseEntity<ProfileDTO.Response> updateProfile(
            @PathVariable Integer userId,
            @Valid @RequestBody ProfileDTO.UpdateRequest request) {
        return ResponseEntity.ok(profileService.updateProfile(userId, request));
    }
}