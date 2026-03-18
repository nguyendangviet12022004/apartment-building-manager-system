package com.viet.backend.service;

import com.viet.backend.dto.ApartmentRequest;
import com.viet.backend.dto.ApartmentResponse;
import com.viet.backend.dto.ApartmentDTO;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.Block;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.BlockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApartmentService {

    private final ApartmentRepository apartmentRepository;
    private final BlockRepository blockRepository;

    @Transactional
    public ApartmentResponse createApartment(ApartmentRequest request) {
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

        return ApartmentResponse.fromEntity(apartmentRepository.save(apartment));
    }

    public Optional<Long> findApartmentIdByUserId(Integer userId) {
        return apartmentRepository
                .findByResidentUserId(userId)
                .map(Apartment::getId);
    }

    private void validateApartmentCode(String code, Block block, Integer floor) {
        // Enforce BR-01: Exactly 12 characters, format XXX-XXXX-XXX
        if (code == null || !code.matches("^[A-Z0-9]{3}-[0-9]{4}-[A-Z0-9]{3}$")) {
            throw new RuntimeException("Invalid apartment code format. Expected XXX-XXXX-XXX (Exactly 12 chars)");
        }

        String[] segments = code.split("-");

        // 1st segment: Building code (3 characters)
        if (!segments[0].equalsIgnoreCase(block.getBlockCode())) {
            throw new RuntimeException(
                    "First segment (" + segments[0] + ") must match building code: " + block.getBlockCode());
        }

        // 2nd segment: Floor (2 digits) + Unit (2 digits)
        int codeFloor = Integer.parseInt(segments[1].substring(0, 2));
        if (codeFloor != floor) {
            throw new RuntimeException("Floor segment (" + codeFloor + ") does not match provided floor: " + floor);
        }

        // 3rd segment: Checksum verification
        // if (!isValidChecksum(segments[0] + "-" + segments[1], segments[2])) {
        // throw new RuntimeException("Invalid checksum segment. Typos detected.");
        // }
    }

    private boolean isValidChecksum(String data, String checksum) {
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

    // Lấy tất cả apartments (dùng cho manager dropdown khi tạo invoice)
    public List<ApartmentDTO> getAll() {
        return apartmentRepository.findAllWithDetails(null)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    // Lấy theo trạng thái used (true = đang có người ở)
    public List<ApartmentDTO> getByUsed(boolean used) {
        return apartmentRepository.findAllWithDetails(used)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public ApartmentDTO getById(Long id) {
        return apartmentRepository.findById(id)
                .map(this::toDTO)
                .orElseThrow(() -> new RuntimeException("Apartment not found: " + id));
    }

    // Lấy apartment theo userId (cho resident xem apartment của mình)
    public ApartmentDTO getByUserId(Integer userId) {
        return apartmentRepository.findByResidentUserId(userId)
                .map(this::toDTO)
                .orElseThrow(() -> new RuntimeException("No apartment for userId: " + userId));
    }

    private ApartmentDTO toDTO(Apartment a) {
        ApartmentDTO.ApartmentDTOBuilder builder = ApartmentDTO.builder()
                .id(a.getId())
                .apartmentCode(a.getApartmentCode())
                .floor(a.getFloor())
                .area(a.getArea())
                .status(a.getStatus())
                .used(a.isUsed());

        if (a.getBlock() != null) {
            builder.blockId(a.getBlock().getId())
                    .blockCode(a.getBlock().getBlockCode());
        }

        if (a.getResident() != null) {
            builder.residentId(a.getResident().getId());
            if (a.getResident().getUser() != null) {
                var user = a.getResident().getUser();
                builder.residentName(user.getFirstname() + " " + user.getLastname())
                        .residentEmail(user.getEmail());
            }
        }

        return builder.build();
    }
}
