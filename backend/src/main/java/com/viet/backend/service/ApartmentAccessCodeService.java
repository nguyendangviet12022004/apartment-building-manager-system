package com.viet.backend.service;

import com.viet.backend.exception.ApartmentAlreadyUsedException;
import com.viet.backend.exception.ExpiredCodeException;
import com.viet.backend.exception.InvalidCodeException;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.ApartmentAccessCode;
import com.viet.backend.repository.ApartmentAccessCodeRepository;
import com.viet.backend.repository.ApartmentRepository;
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

    @Transactional
    public String generateCode(Long apartmentId, String email) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found with id: " + apartmentId));

        if (apartment.isUsed()) {
            throw new ApartmentAlreadyUsedException("Apartment is already occupied and cannot generate new codes");
        }

        // Deactivate all previous codes
        apartmentAccessCodeRepository.deactivateAllByApartmentId(apartmentId);

        // Generate new 6-digit code
        String code = String.format("%06d", new Random().nextInt(1000000));

        ApartmentAccessCode accessCode = ApartmentAccessCode.builder()
                .code(code)
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

        // Activate logic: Inactivate the code after successful validation
        accessCode.setActive(false);
        apartmentAccessCodeRepository.save(accessCode);

        // Mark apartment as used
        Apartment apartment = accessCode.getApartment();
        apartment.setUsed(true);
        apartmentRepository.save(apartment);

        return apartment.getId();
    }
}
