package com.viet.backend.service;

import com.viet.backend.dto.ResidentDTO;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.Resident;
import com.viet.backend.model.User;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.ResidentRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing residents (Manager role)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ResidentManagementService {

    private final UserRepository userRepository;
    private final ResidentRepository residentRepository;
    private final ApartmentRepository apartmentRepository;

    /**
     * Get all residents with filtering and pagination
     */
    @Transactional(readOnly = true)
    public ResidentDTO.ResidentListResponse getResidents(ResidentDTO.ResidentFilterRequest request) {
        log.info("Fetching residents with filters: search={}, building={}, status={}, type={}", 
                request.getSearch(), request.getBuilding(), request.getStatus(), request.getType());

        // Set default pagination
        int page = request.getPage() != null ? request.getPage() : 0;
        int pageSize = request.getPageSize() != null ? request.getPageSize() : 20;
        
        // Get all residents
        List<Resident> allResidents = residentRepository.findAllWithUser();
        log.info("Found {} total residents in database", allResidents.size());
        
        // Map to DTOs and filter out nulls
        List<ResidentDTO.ResidentListItem> allResidentItems = allResidents.stream()
                .map(this::mapToListItem)
                .filter(item -> item != null)  // Filter out null items from mapping errors
                .collect(Collectors.toList());
        
        log.info("Successfully mapped {} residents to DTOs", allResidentItems.size());
        
        // Apply filters
        List<ResidentDTO.ResidentListItem> filteredResidents = allResidentItems.stream()
                .filter(item -> applyFilters(item, request))
                .collect(Collectors.toList());

        log.info("After filtering: {} residents match criteria", filteredResidents.size());

        // Calculate pagination
        int totalCount = filteredResidents.size();
        int totalPages = totalCount > 0 ? (int) Math.ceil((double) totalCount / pageSize) : 0;
        int fromIndex = page * pageSize;
        int toIndex = Math.min(fromIndex + pageSize, totalCount);

        // Get paginated results
        List<ResidentDTO.ResidentListItem> paginatedResidents = fromIndex < totalCount
                ? filteredResidents.subList(fromIndex, toIndex)
                : new ArrayList<>();

        log.info("Returning {} residents (page {}/{}, total: {})", 
                paginatedResidents.size(), page + 1, totalPages, totalCount);

        return ResidentDTO.ResidentListResponse.builder()
                .residents(paginatedResidents)
                .totalCount(totalCount)
                .page(page)
                .pageSize(pageSize)
                .totalPages(totalPages)
                .build();
    }

    /**
     * Map Resident entity to ResidentListItem DTO
     */
    private ResidentDTO.ResidentListItem mapToListItem(Resident resident) {
        try {
            User user = resident.getUser();
            
            if (user == null) {
                log.warn("Resident {} has no associated user - skipping", resident.getId());
                return null;
            }
            
            log.debug("Mapping resident {} with user {}", resident.getId(), user.getEmail());
            
            // Get apartment info
            List<Apartment> apartments = apartmentRepository.findByResidentId(resident.getId());
            Apartment apartment = apartments.isEmpty() ? null : apartments.get(0);
            
            if (apartment != null) {
                log.debug("Resident {} has apartment: {}", resident.getId(), apartment.getApartmentCode());
            } else {
                log.debug("Resident {} has no apartment assigned", resident.getId());
            }

            String firstName = user.getFirstname() != null ? user.getFirstname() : "";
            String lastName = user.getLastname() != null ? user.getLastname() : "";
            String fullName = (firstName + " " + lastName).trim();
            if (fullName.isEmpty()) {
                fullName = user.getEmail();
            }

            String initials = computeInitials(firstName, lastName);
            
            // Determine status (ACTIVE if has apartment, otherwise INACTIVE)
            String status = (apartment != null) ? "ACTIVE" : "INACTIVE";

            ResidentDTO.ResidentListItem item = ResidentDTO.ResidentListItem.builder()
                    .userId(user.getId())
                    .residentId(resident.getId())
                    .fullName(fullName)
                    .firstname(firstName)
                    .lastname(lastName)
                    .email(user.getEmail())
                    .phone(user.getPhone())
                    .avatarUrl(user.getAvatarUrl())
                    .initials(initials)
                    .apartmentId(apartment != null ? apartment.getId() : null)
                    .apartmentCode(apartment != null ? apartment.getApartmentCode() : null)
                    .blockCode(apartment != null && apartment.getBlock() != null 
                            ? apartment.getBlock().getBlockCode() : null)
                    .unitNumber(apartment != null ? apartment.getApartmentCode() : null)
                    .status(status)
                    .ownershipType("OWNER")  // Default ownership type
                    .identityCard(resident.getIdentityCard())
                    .emergencyContact(resident.getEmergencyContact())
                    .moveInDate(null)  // Extend when move-in date is added
                    .build();
            
            log.debug("Successfully mapped resident: {} - {} ({})", 
                    item.getResidentId(), item.getFullName(), item.getStatus());
            return item;
            
        } catch (Exception e) {
            log.error("Error mapping resident {}: {}", resident.getId(), e.getMessage(), e);
            return null;
        }
    }

    /**
     * Apply filters to resident item
     */
    private boolean applyFilters(ResidentDTO.ResidentListItem item, ResidentDTO.ResidentFilterRequest request) {
        if (item == null) {
            return false;
        }
        
        // Search filter (name, email, phone, apartment code)
        if (request.getSearch() != null && !request.getSearch().isEmpty()) {
            String search = request.getSearch().toLowerCase();
            boolean matchesSearch = 
                (item.getFullName() != null && item.getFullName().toLowerCase().contains(search)) ||
                (item.getEmail() != null && item.getEmail().toLowerCase().contains(search)) ||
                (item.getPhone() != null && item.getPhone().toLowerCase().contains(search)) ||
                (item.getApartmentCode() != null && item.getApartmentCode().toLowerCase().contains(search));
            
            if (!matchesSearch) {
                log.debug("Resident {} does not match search: {}", item.getResidentId(), search);
                return false;
            }
        }

        // Building/Block filter
        if (request.getBuilding() != null && !request.getBuilding().isEmpty()) {
            if (item.getBlockCode() == null || !item.getBlockCode().equalsIgnoreCase(request.getBuilding())) {
                log.debug("Resident {} does not match building filter: {}", item.getResidentId(), request.getBuilding());
                return false;
            }
        }

        // Status filter
        if (request.getStatus() != null && !request.getStatus().isEmpty()) {
            if (!request.getStatus().equalsIgnoreCase(item.getStatus())) {
                log.debug("Resident {} does not match status filter: {}", item.getResidentId(), request.getStatus());
                return false;
            }
        }

        // Type filter
        if (request.getType() != null && !request.getType().isEmpty()) {
            if (!request.getType().equalsIgnoreCase(item.getOwnershipType())) {
                log.debug("Resident {} does not match type filter: {}", item.getResidentId(), request.getType());
                return false;
            }
        }

        return true;
    }

    /**
     * Compute user initials from first and last name
     */
    private String computeInitials(String firstname, String lastname) {
        StringBuilder initials = new StringBuilder();
        
        if (firstname != null && !firstname.isEmpty()) {
            initials.append(firstname.charAt(0));
        }
        
        if (lastname != null && !lastname.isEmpty()) {
            initials.append(lastname.charAt(0));
        }
        
        return initials.length() > 0 ? initials.toString().toUpperCase() : "R";
    }

    /**
     * Get resident details by resident ID
     */
    @Transactional(readOnly = true)
    public ResidentDTO.ResidentDetailResponse getResidentDetails(Long residentId) {
        log.info("Fetching details for resident ID: {}", residentId);
        
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new RuntimeException("Resident not found with ID: " + residentId));
        
        User user = resident.getUser();
        if (user == null) {
            throw new RuntimeException("User not found for resident ID: " + residentId);
        }
        
        // Get apartment info
        List<Apartment> apartments = apartmentRepository.findByResidentId(residentId);
        Apartment apartment = apartments.isEmpty() ? null : apartments.get(0);
        
        String firstName = user.getFirstname() != null ? user.getFirstname() : "";
        String lastName = user.getLastname() != null ? user.getLastname() : "";
        String fullName = (firstName + " " + lastName).trim();
        if (fullName.isEmpty()) {
            fullName = user.getEmail();
        }
        
        // Determine status
        String status = (apartment != null) ? "ACTIVE" : "INACTIVE";
        
        // Generate resident code (RES-xxxxx format)
        String residentCode = "RES-" + String.format("%05d", residentId);
        
        // Format building name
        String building = apartment != null && apartment.getBlock() != null 
                ? "Building " + apartment.getBlock().getBlockCode() 
                : null;
        
        // Format unit (apartment code)
        String unit = apartment != null ? apartment.getApartmentCode() : null;
        
        // Determine apartment type based on area (simplified logic)
        String apartmentType = null;
        if (apartment != null && apartment.getArea() != null) {
            double area = apartment.getArea();
            if (area < 60) {
                apartmentType = "1BR Apartment";
            } else if (area < 80) {
                apartmentType = "2BR Apartment";
            } else if (area < 100) {
                apartmentType = "3BR Apartment";
            } else {
                apartmentType = "4BR Apartment";
            }
        }
        
        return ResidentDTO.ResidentDetailResponse.builder()
                .userId(user.getId())
                .residentId(residentId)
                .fullName(fullName)
                .firstname(firstName)
                .lastname(lastName)
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .dateOfBirth(user.getDateOfBirth())
                .gender(user.getGender())
                .identityCard(resident.getIdentityCard())
                .status(status)
                .residentCode(residentCode)
                .ownershipType("OWNER")  // Default ownership type
                .apartmentId(apartment != null ? apartment.getId() : null)
                .building(building)
                .unit(unit)
                .apartmentType(apartmentType)
                .area(apartment != null ? apartment.getArea() : null)
                .moveInDate(null)  // Extend when move-in date is added to database
                .emergencyContact(resident.getEmergencyContact())
                .emergencyContactRelationship(resident.getEmergencyContactRelationship())
                .build();
    }
}
