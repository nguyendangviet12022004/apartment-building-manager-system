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

        String code = request.getApartmentCode();
        validateApartmentCode(code, block, request.getFloor());

        if (apartmentRepository.findByApartmentCodeWithBlock(code).isPresent()) {
            throw new RuntimeException("Apartment code already exists system-wide: " + code);
        }

        Apartment apartment = Apartment.builder()
                .apartmentCode(code)
                .floor(request.getFloor())
                .area(request.getArea())
                .status(request.getStatus())
                .block(block)
                .used(false)
                .build();

        return apartmentRepository.save(apartment);
    }

    private void validateApartmentCode(String code, Block block, Integer floor) {
        // Format: XXX-XXXX-XXX (Exactly 12 characters)
        if (code == null || !code.matches("^[A-Z0-9]{3}-[0-9]{4}-[A-Z0-9]{3}$")) {
            throw new RuntimeException("Invalid apartment code format. Expected XXX-XXXX-XXX (12 chars)");
        }

        String[] segments = code.split("-");

        // 1st segment: Building code (case-insensitive alphanumeric)
        if (!segments[0].equalsIgnoreCase(block.getBlockCode())) {
            throw new RuntimeException("First segment must match building code: " + block.getBlockCode());
        }

        // 2nd segment: Floor (2 digits) + Unit (2 digits)
        int codeFloor = Integer.parseInt(segments[1].substring(0, 2));
        if (codeFloor != floor) {
            throw new RuntimeException("Floor segment (" + codeFloor + ") does not match provided floor: " + floor);
        }

        // 3rd segment: Checksum verification (Simple sum-based for demo)
        if (!isValidChecksum(segments[0] + "-" + segments[1], segments[2])) {
            throw new RuntimeException("Invalid checksum segment. Typos detected.");
        }
    }

    private boolean isValidChecksum(String data, String checksum) {
        // Simple logic: sum of chars % 1000 converted to hex/alphanumeric
        int sum = 0;
        for (char c : data.toCharArray())
            sum += c;
        String expected = Integer.toHexString(sum).toUpperCase();
        while (expected.length() < 3)
            expected = "0" + expected;
        if (expected.length() > 3)
            expected = expected.substring(expected.length() - 3);

        return checksum.equals(expected);
    }
}
