package com.viet.backend.service;

import com.viet.backend.dto.ApartmentRequest;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.Block;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.BlockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ApartmentService {

    private final ApartmentRepository apartmentRepository;
    private final BlockRepository blockRepository;

    @Transactional
    public Apartment createApartment(ApartmentRequest request) {
        Block block = blockRepository.findById(request.getBlockId())
                .orElseThrow(() -> new RuntimeException("Block not found with id: " + request.getBlockId()));

        if (apartmentRepository.findByApartmentCodeWithBlock(request.getApartmentCode()).isPresent()) {
            throw new RuntimeException("Apartment code already exists: " + request.getApartmentCode());
        }

        Apartment apartment = Apartment.builder()
                .apartmentCode(request.getApartmentCode())
                .floor(request.getFloor())
                .area(request.getArea())
                .status(request.getStatus())
                .block(block)
                .used(false) // New apartments are unused by default
                .build();

        return apartmentRepository.save(apartment);
    }
}
