package com.viet.backend.dto;

import lombok.*;

import java.util.List;

public class ResidentDTO {

    /**
     * Response DTO for resident list item
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResidentListItem {
        private Integer userId;
        private Long residentId;
        private String fullName;
        private String firstname;
        private String lastname;
        private String email;
        private String phone;
        private String avatarUrl;
        private String initials;
        
        // Apartment info
        private Long apartmentId;
        private String apartmentCode;
        private String blockCode;
        private String unitNumber;
        
        // Status
        private String status;           // ACTIVE, INACTIVE
        private String ownershipType;    // OWNER, TENANT
        
        // Additional info
        private String identityCard;
        private String emergencyContact;
        private String moveInDate;
    }

    /**
     * Response DTO for paginated resident list
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResidentListResponse {
        private List<ResidentListItem> residents;
        private int totalCount;
        private int page;
        private int pageSize;
        private int totalPages;
    }

    /**
     * Request DTO for filtering residents
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResidentFilterRequest {
        private String search;           // Search by name, email, phone
        private String building;         // Filter by building/block
        private String status;           // Filter by status (ACTIVE, INACTIVE)
        private String type;             // Filter by type (OWNER, TENANT)
        private Integer page;
        private Integer pageSize;
    }

    /**
     * Response DTO for resident details
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResidentDetailResponse {
        // Personal Information
        private Integer userId;
        private Long residentId;
        private String fullName;
        private String firstname;
        private String lastname;
        private String email;
        private String phone;
        private String avatarUrl;
        private String dateOfBirth;
        private String gender;
        private String identityCard;
        
        // Status
        private String status;           // ACTIVE, INACTIVE
        private String residentCode;     // e.g., RES-49201
        private String ownershipType;    // OWNER, TENANT
        
        // Apartment Information
        private Long apartmentId;
        private String building;         // e.g., Building A
        private String unit;             // e.g., 402-B
        private String apartmentType;    // e.g., 2BR Apartment
        private Double area;             // e.g., 75.0 (m²)
        private String moveInDate;       // e.g., January 15, 2023
        
        // Emergency Contact
        private String emergencyContact;
        private String emergencyContactRelationship;
    }
}
