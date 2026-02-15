package com.viet.backend.service;

import com.viet.backend.config.JwtService;
import com.viet.backend.dto.AuthenticationRequest;
import com.viet.backend.dto.AuthenticationResponse;
import com.viet.backend.dto.RegisterRequest;
import com.viet.backend.mapper.UserMapper;
import com.viet.backend.repository.ApartmentAccessCodeRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import com.viet.backend.exception.*;
import com.viet.backend.model.Role;
import com.viet.backend.model.ApartmentAccessCode;
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

  @Transactional
  public AuthenticationResponse register(RegisterRequest request) {
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

    var jwtToken = jwtService.generateToken(savedUser);
    return AuthenticationResponse.builder()
        .token(jwtToken)
        .build();
  }

  public AuthenticationResponse authenticate(AuthenticationRequest request) {
    authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(
            request.getEmail(),
            request.getPassword()));
    var user = repository.findByEmail(request.getEmail())
        .orElseThrow();
    var jwtToken = jwtService.generateToken(user);
    return AuthenticationResponse.builder()
        .token(jwtToken)
        .build();
  }
}
