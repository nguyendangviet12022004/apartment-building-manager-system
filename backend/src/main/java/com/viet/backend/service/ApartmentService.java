package com.viet.backend.service;

import com.viet.backend.dto.ApartmentRequest;
import com.viet.backend.dto.ApartmentResponse;
import com.viet.backend.dto.ApartmentDTO;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.Block;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.BlockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
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

        String code = generateApartmentCode(block, request.getFloor());
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

    @Transactional
    public java.util.Map<String, Object> bulkCreateApartments(com.viet.backend.dto.BulkCreateApartmentRequest request) {
        Block block = blockRepository.findById(request.getBlockId())
                .orElseThrow(() -> new RuntimeException("Block not found with id: " + request.getBlockId()));

        int unitCounter = 1;
        List<String> createdCodes = new java.util.ArrayList<>();
        List<Apartment> apartmentsToSave = new java.util.ArrayList<>();

        for (com.viet.backend.dto.BulkCreateApartmentRequest.ApartmentUnitRequest unitReq : request.getUnits()) {
            String floorPart = String.format("%02d", request.getFloor()) + String.format("%02d", unitCounter);
            String base = block.getBlockCode() + "-" + floorPart;

            int sum = 0;
            for (char c : base.toCharArray()) {
                sum += c;
            }

            String checksum = Integer.toHexString(sum).toUpperCase();
            while (checksum.length() < 3) {
                checksum = "0" + checksum;
            }
            if (checksum.length() > 3) {
                checksum = checksum.substring(checksum.length() - 3);
            }

            String code = base + "-" + checksum;

            if (apartmentRepository.findByApartmentCodeWithBlock(code).isPresent()) {
                throw new RuntimeException("Apartment code already exists system-wide: " + code);
            }

            Apartment apartment = Apartment.builder()
                    .apartmentCode(code)
                    .floor(request.getFloor())
                    .area(unitReq.getArea())
                    .status("VACANT")
                    .block(block)
                    .used(false)
                    .build();

            apartmentsToSave.add(apartment);
            createdCodes.add(code);

            unitCounter++;
            if (unitCounter > 99) {
                throw new RuntimeException("Maximum units per floor reached.");
            }
        }

        apartmentRepository.saveAll(apartmentsToSave);

        return java.util.Map.of(
                "totalCreated", createdCodes.size(),
                "createdCodes", createdCodes);
    }

    @Transactional
    public ApartmentResponse updateApartment(Long id, ApartmentRequest request) {
        Apartment apartment = apartmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Apartment not found: " + id));

        Block block = blockRepository.findById(request.getBlockId())
                .orElseThrow(() -> new RuntimeException("Block not found with: " + request.getBlockId()));

        String code = request.getApartmentCode();
        validateApartmentCode(code, block, request.getFloor());

        Optional<Apartment> existingCodeApt = apartmentRepository.findByApartmentCodeWithBlock(code);
        if (existingCodeApt.isPresent() && !existingCodeApt.get().getId().equals(id)) {
            throw new RuntimeException("Apartment code already exists system-wide: " + code);
        }

        apartment.setApartmentCode(code);
        apartment.setFloor(request.getFloor());
        apartment.setArea(request.getArea());
        apartment.setStatus(request.getStatus());
        apartment.setBlock(block);

        return ApartmentResponse.fromEntity(apartmentRepository.save(apartment));
    }

    public Optional<Long> findApartmentIdByUserId(Integer userId) {
        return apartmentRepository
                .findByResidentUserId(userId)
                .map(Apartment::getId);
    }

    private void validateApartmentCode(String code, Block block, Integer floor) {
        // Enforce format BlockCode-Floor-Unit (e.g. VIN-05-01)
        if (code == null || !code.matches("^[A-Z0-9]{3}-\\d{2}-\\d{2}$")) {
            throw new RuntimeException("Invalid apartment code format. Expected XXX-XX-XX (e.g. VIN-05-01)");
        }

        String[] segments = code.split("-");

        // 1st segment: Building code (3 characters)
        if (!segments[0].equalsIgnoreCase(block.getBlockCode())) {
            throw new RuntimeException("First segment (" + segments[0] + ") must match building code: " + block.getBlockCode());
        }

        // 2nd segment: Floor (2 digits)
        int codeFloor = Integer.parseInt(segments[1]);
        if (codeFloor != floor) {
            throw new RuntimeException("Floor segment (" + segments[1] + ") does not match provided floor: " + floor);
        }
    }


    private String generateApartmentCode(Block block, Integer floor) {
        String blockCode = block.getBlockCode();
        int unitCounter = 1;
        String code = "";

        while (true) {
            code = String.format("%s-%02d-%02d", blockCode, floor, unitCounter);

            if (apartmentRepository.findByApartmentCodeWithBlock(code).isEmpty()) {
                break;
            }

            unitCounter++;
            if (unitCounter > 99) {
                throw new RuntimeException("Maximum units per floor reached.");
            }
        }

        return code;
    }

    // Lấy tất cả apartments (dùng cho manager dropdown khi tạo invoice)
    public List<ApartmentDTO> getAll() {
        return apartmentRepository.findAllWithDetails(null)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public Page<ApartmentDTO> getApartments(String keyword, Long blockId, Integer floor, String status, Boolean used,
            Pageable pageable) {
        Specification<Apartment> spec = Specification.where(null);

        if (keyword != null && !keyword.trim().isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.like(cb.lower(root.get("apartmentCode")),
                    "%" + keyword.toLowerCase() + "%"));
        }

        if (blockId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("block").get("id"), blockId));
        }

        if (floor != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("floor"), floor));
        }

        if (status != null && !status.trim().isEmpty() && !status.equalsIgnoreCase("ALL")) {
            spec = spec.and((root, query, cb) -> cb.equal(cb.upper(root.get("status")), status.toUpperCase()));
        }

        if (used != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("used"), used));
        }

        // To avoid N+1 issues when mapping to DTO, we can use EntityGraph or let batch
        // fetching handle it
        return apartmentRepository.findAll(spec, pageable).map(this::toDTO);
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
