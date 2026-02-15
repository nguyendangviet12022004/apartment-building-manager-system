package com.viet.backend.controller;

import com.viet.backend.service.ApartmentAccessCodeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/apartment-codes")
@RequiredArgsConstructor
public class ApartmentAccessCodeController {

    private final ApartmentAccessCodeService apartmentAccessCodeService;

    @PostMapping("/{apartmentId}/generate")
    public ResponseEntity<String> generateCode(
            @PathVariable Long apartmentId,
            @RequestParam(required = false) String email) {
        String code = apartmentAccessCodeService.generateCode(apartmentId, email);
        return ResponseEntity.ok(code);
    }

    @PostMapping("/verify")
    public ResponseEntity<Long> verifyCode(@RequestParam String code) {
        Long apartmentId = apartmentAccessCodeService.validateAndActivate(code);
        return ResponseEntity.ok(apartmentId);
    }
}
