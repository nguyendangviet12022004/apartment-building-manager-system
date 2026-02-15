package com.viet.backend.service;

import com.viet.backend.exception.*;
import com.viet.backend.model.*;
import com.viet.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class ApartmentAccessCodeService {

    private final ApartmentAccessCodeRepository apartmentAccessCodeRepository;
    private final ApartmentRepository apartmentRepository;
    private final EmailService emailService;
    private final UserRepository userRepository;
    private final ResidentRepository residentRepository;

    @Transactional
    public String generateCode(Long apartmentId, String email) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found with id: " + apartmentId));

        if (apartment.isUsed()) {
            throw new ApartmentAlreadyUsedException("Apartment is already occupied and cannot generate new codes");
        }

        // Check if user already exists
        var userOptional = userRepository.findByEmail(email);
        if (userOptional.isPresent()) {
            linkUserToApartment(userOptional.get(), apartment, null, null);
            return "ALREADY_LINKED";
        }

        // Deactivate all previous codes
        apartmentAccessCodeRepository.deactivateAllByApartmentId(apartmentId);

        // Generate new 6-digit code
        String code = String.format("%06d", new Random().nextInt(1000000));

        ApartmentAccessCode accessCode = ApartmentAccessCode.builder()
                .code(code)
                .email(email)
                .apartment(apartment)
                .expiryTime(LocalDateTime.now().plusMinutes(5))
                .isActive(true)
                .build();

        apartmentAccessCodeRepository.save(accessCode);

        // Send email with the generated code
        if (email != null && !email.isBlank()) {
            emailService.sendAccessCodeEmail(email, code);
        }

        return code;
    }

    @Transactional
    public void linkUserToApartment(User user, Apartment apartment, String identityCard, String emergencyContact) {
        // Find or create resident
        Resident resident = residentRepository.findByUserId(user.getId())
                .orElseGet(() -> residentRepository.save(Resident.builder()
                        .user(user)
                        .identityCard(identityCard)
                        .emergencyContact(emergencyContact)
                        .build()));

        // Update identity info if it was missing but provided now
        if (identityCard != null && (resident.getIdentityCard() == null || resident.getIdentityCard().isEmpty())) {
            resident.setIdentityCard(identityCard);
        }
        if (emergencyContact != null
                && (resident.getEmergencyContact() == null || resident.getEmergencyContact().isEmpty())) {
            resident.setEmergencyContact(emergencyContact);
        }
        residentRepository.saveAndFlush(resident);

        // Directly update the apartment with the resident (N:1)
        apartment.setResident(resident);
        apartment.setUsed(true);
        apartmentRepository.saveAndFlush(apartment);
    }

    @Transactional
    public Long validateAndActivate(String code) {
        ApartmentAccessCode accessCode = apartmentAccessCodeRepository.findByCode(code)
                .orElseThrow(() -> new InvalidCodeException("Code is incorrect or does not exist"));

        if (!accessCode.isActive()) {
            throw new InvalidCodeException("Code has already been used or is inactive");
        }

        if (accessCode.getExpiryTime().isBefore(LocalDateTime.now())) {
            accessCode.setActive(false);
            apartmentAccessCodeRepository.save(accessCode);
            throw new ExpiredCodeException("Code has expired");
        }

        // Mark apartment as used and link to resident if user exists
        Apartment apartment = accessCode.getApartment();

        // Try to link user if they registered between code generation and verification
        if (accessCode.getEmail() != null) {
            var userOptional = userRepository.findByEmail(accessCode.getEmail());
            if (userOptional.isPresent()) {
                linkUserToApartment(userOptional.get(), apartment, null, null);

                // ONLY deactivate if we successfully linked a user
                accessCode.setActive(false);
                apartmentAccessCodeRepository.save(accessCode);
            }
        }
        // If no user exists yet, we keep the code ACTIVE so they can register with it
        // later.
        // We just return the apartment ID to show it's a valid code.

        return apartment.getId();
    }
}
