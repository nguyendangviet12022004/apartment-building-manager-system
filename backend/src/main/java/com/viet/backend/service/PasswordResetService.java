package com.viet.backend.service;

import com.viet.backend.exception.ExpiredCodeException;
import com.viet.backend.exception.InvalidCodeException;
import com.viet.backend.model.PasswordResetCode;
import com.viet.backend.model.User;
import com.viet.backend.repository.PasswordResetCodeRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private final PasswordResetCodeRepository codeRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public void generateResetCode(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found with email: " + email));

        // Delete any existing codes for this user to keep it clean
        codeRepository.deleteByUser(user);

        // Generate 6 digit code
        String code = String.format("%06d", new SecureRandom().nextInt(999999));

        PasswordResetCode resetCode = PasswordResetCode.builder()
                .code(code)
                .user(user)
                .expiryDate(LocalDateTime.now().plusMinutes(15)) // Valid for 15 minutes
                .isActive(true)
                .build();

        codeRepository.save(resetCode);
        emailService.sendPasswordResetEmail(email, code);
    }

    public void verifyResetCode(String email, String code) {
        PasswordResetCode resetCode = codeRepository.findByCodeAndUser_EmailAndIsActiveTrue(code, email)
                .orElseThrow(() -> new InvalidCodeException("Invalid verification code"));

        if (resetCode.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new ExpiredCodeException("Verification code has expired");
        }

        // As per business rule: Just verify, do not deactivate yet.
    }

    @Transactional
    public void resetPassword(String email, String code, String newPassword) {
        PasswordResetCode resetCode = codeRepository.findByCodeAndUser_EmailAndIsActiveTrue(code, email)
                .orElseThrow(() -> new InvalidCodeException("Invalid verification code"));

        if (resetCode.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new ExpiredCodeException("Verification code has expired");
        }

        // Update user password
        User user = resetCode.getUser();
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Deactivate code after successful reset
        resetCode.setActive(false);
        codeRepository.save(resetCode);
    }
}
