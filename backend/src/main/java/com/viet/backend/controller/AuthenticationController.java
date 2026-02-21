package com.viet.backend.controller;

import com.viet.backend.dto.AuthenticationRequest;
import com.viet.backend.dto.AuthenticationResponse;
import com.viet.backend.dto.ChangePasswordRequest;
import com.viet.backend.dto.ForgotPasswordRequest;
import com.viet.backend.dto.RegisterRequest;
import com.viet.backend.dto.ResetPasswordRequest;
import com.viet.backend.dto.VerifyCodeRequest;
import com.viet.backend.service.AuthenticationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/v1/auth")
@RequiredArgsConstructor
public class AuthenticationController {

  private final AuthenticationService service;

  @GetMapping("/test-token")
  public ResponseEntity<Integer> testToken(@RequestHeader("X-User-ID") Integer userId) {
    return ResponseEntity.ok(userId);
  }

  @PostMapping("/register")
  public ResponseEntity<AuthenticationResponse> register(
      @Valid @RequestBody RegisterRequest request) {
    return ResponseEntity.ok(service.register(request));
  }

  @PostMapping("/login")
  public ResponseEntity<AuthenticationResponse> authenticate(
      @Valid @RequestBody AuthenticationRequest request) {
    return ResponseEntity.ok(service.authenticate(request));
  }

  @PostMapping("/password/forgot")
  public ResponseEntity<String> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
    service.generateResetCode(request.getEmail());
    return ResponseEntity.ok("Verification code sent to email");
  }

  @PostMapping("/password/verify")
  public ResponseEntity<String> verifyCode(@Valid @RequestBody VerifyCodeRequest request) {
    service.verifyResetCode(request.getEmail(), request.getCode());
    return ResponseEntity.ok("Code is valid");
  }

  @PostMapping("/password/reset")
  public ResponseEntity<String> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
    service.resetPassword(request.getEmail(), request.getCode(), request.getNewPassword());
    return ResponseEntity.ok("Password has been reset successfully");
  }

  @PostMapping("/password/change")
  public ResponseEntity<String> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
    service.changePassword(request);
    return ResponseEntity.ok("Password has been changed successfully");
  }

  @PostMapping("/fcm-token/update")
  public ResponseEntity<String> updateFcmToken(@RequestBody com.viet.backend.dto.FcmTokenRequest request) {
    service.updateFcmToken(request.getEmail(), request.getToken());
    return ResponseEntity.ok("FCM token updated successfully");
  }

  @PostMapping("/fcm-token/remove")
  public ResponseEntity<String> removeFcmToken(@RequestBody com.viet.backend.dto.FcmTokenRequest request) {
    service.removeFcmToken(request.getEmail());
    return ResponseEntity.ok("FCM token removed successfully");
  }
}
