package com.viet.backend.service;

import com.viet.backend.config.JwtService;
import com.viet.backend.dto.AuthenticationRequest;
import com.viet.backend.dto.AuthenticationResponse;
import com.viet.backend.dto.RegisterRequest;
import com.viet.backend.mapper.UserMapper;
import com.viet.backend.repository.ApartmentAccessCodeRepository;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.ResidentRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import com.viet.backend.exception.*;
import com.viet.backend.model.*;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

  private final UserRepository repository;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;
  private final AuthenticationManager authenticationManager;
  private final UserMapper userMapper;
  private final ApartmentAccessCodeService accessCodeService;
  private final ApartmentAccessCodeRepository accessCodeRepository;
  private final ResidentRepository residentRepository;
  private final ApartmentRepository apartmentRepository;

  @Transactional
  public AuthenticationResponse register(RegisterRequest request) {
    validatePassword(request);
    var user = userMapper.toEntity(request);
    user.setPassword(passwordEncoder.encode(request.getPassword()));

    ApartmentAccessCode validCode = null;

    if (request.getApartmentId() != null) {
      // Find valid invitation code
      validCode = accessCodeRepository
          .findByEmailAndApartment_IdAndIsActiveTrue(user.getEmail(), request.getApartmentId())
          .orElseThrow(() -> new InvalidInvitationException(
              "No valid invitation found for email " + user.getEmail() + " and apartment " + request.getApartmentId()));

      user.setRole(Role.RESIDENT);
    } else {
      user.setRole(request.getRole());
    }

    var savedUser = repository.save(user);

    // If there was a valid invitation, link the user to the apartment
    if (validCode != null) {
      var apartment = validCode.getApartment();
      accessCodeService.linkUserToApartment(savedUser, apartment, request.getIdentityCard(),
          request.getEmergencyContact());
      validCode.setActive(false);
      accessCodeRepository.save(validCode);
    }

    var jwtToken = jwtService.generateToken(getExtraClaims(savedUser), savedUser);
    var refreshToken = jwtService.generateRefreshToken(savedUser);

    return AuthenticationResponse.builder()
        .accessToken(jwtToken)
        .refreshToken(refreshToken)
        .build();
  }

  public AuthenticationResponse authenticate(AuthenticationRequest request) {
    authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(
            request.getEmail(),
            request.getPassword()));
    var user = repository.findByEmail(request.getEmail())
        .orElseThrow();
    var jwtToken = jwtService.generateToken(getExtraClaims(user), user);
    var refreshToken = jwtService.generateRefreshToken(user);

    return AuthenticationResponse.builder()
        .accessToken(jwtToken)
        .refreshToken(refreshToken)
        .build();
  }

  private Map<String, Object> getExtraClaims(User user) {
    Map<String, Object> extraClaims = new HashMap<>();
    extraClaims.put("user_id", user.getId());
    extraClaims.put("role", user.getRole().name());

    if (user.getRole() == Role.RESIDENT) {
      residentRepository.findByUserId(user.getId()).ifPresent(resident -> {
        var apartmentIds = apartmentRepository.findByResidentId(resident.getId()).stream()
            .map(Apartment::getId)
            .collect(Collectors.toList());
        extraClaims.put("apartment_ids", apartmentIds);
        if (!apartmentIds.isEmpty()) {
          extraClaims.put("apartment_id", apartmentIds.get(0));
        }
      });
    }
    return extraClaims;
  }

  private void validatePassword(RegisterRequest request) {
    String password = request.getPassword();
    String email = request.getEmail();

    // Prevent same as email
    if (password.equalsIgnoreCase(email) || email.contains(password)) {
      throw new RuntimeException("Password cannot be same as or contained in email");
    }

    // Common passwords list (minimal sample of 10k list)
    java.util.List<String> commonPasswords = java.util.Arrays.asList(
        "password", "12345678", "qwertyuiop", "admin123", "apartment123", "Complex!123");

    if (commonPasswords.contains(password.toLowerCase())) {
      throw new RuntimeException("Password is too common. Please choose a more unique password.");
    }
  }
}
