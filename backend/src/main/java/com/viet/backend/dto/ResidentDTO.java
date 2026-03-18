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
}
