package com.viet.backend.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

public class ProfileDTO {

    // ─────────────────────────────────────────────────────────────────────────
    // GET /api/v1/profile/{userId}  →  Response
    // ─────────────────────────────────────────────────────────────────────────
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Response {

        // ── User basics ───────────────────────────────────────────────────────
        private Integer userId;
        private String  firstname;
        private String  lastname;
        private String  fullName;

        /** Masked email: j***@gmail.com  (BR-03) */
        private String  emailMasked;
        /** Full email – only in edit mode, kept here for FE convenience */
        private String  emailFull;
        private boolean emailVerified;   // BR-04

        /** Masked phone: 090-***-4567  (BR-03) */
        private String  phoneMasked;
        private String  phoneFull;           // full, for edit mode
        private boolean phoneVerified;   // BR-04

        // ── Personal ─────────────────────────────────────────────────────────
        private String  accountId;       // "#RE-XXXXX" – full display (BR-03)
        private String  dateOfBirth;     // "yyyy-MM-dd" or null
        private String  gender;          // "Male" | "Female" | "Other" | null

        // ── Resident extras ───────────────────────────────────────────────────
        private String  identityCard;
        private String  emergencyContactName;
        private String  emergencyContactPhone;
        private String  emergencyContactRelationship;  // Spouse, Parent, Sibling, Friend, Other

        // ── Apartment ─────────────────────────────────────────────────────────
        private Long    apartmentId;
        private String  apartmentCode;       // e.g. "A1701"
        private String  apartmentCodeFull;   // e.g. "A17-1701-XYZ"
        private String  apartmentName;       // e.g. "A1701"
        private String  blockCode;           // e.g. "A17"  → display "Tower A17"
        private Integer floor;
        private String  unitNumber;          // last segment of code
        private Double  area;
        private String  apartmentType;       // e.g. "2BR" / "3 Bedroom Suite"
        private String  apartmentStatus;     // status of apartment
        private String  moveInDate;          // "yyyy-MM-dd" or null
        private String  ownershipStatus;     // "Owner" | "Tenant" | "Family Member"

        // ── Vehicles ──────────────────────────────────────────────────────────
        private List<VehicleInfo> vehicles;

        // ── Security ──────────────────────────────────────────────────────────
        private LocalDateTime lastLogin;
        private boolean twoFactorEnabled;

        // ── Preferences ───────────────────────────────────────────────────────
        private String  language;           // e.g. "English"
        private Boolean emailNotifications; // true/false
        private Boolean pushNotifications;  // true/false
        private String  theme;              // e.g. "Light" | "Dark" | "Auto"

        // ── Profile photo ─────────────────────────────────────────────────────
        private String  avatarUrl;       // Cloudinary URL or null
        private String  initials;        // "JD" fallback

        // ── Completion (BR-01) ────────────────────────────────────────────────
        private int     profileCompletion;   // 0-100
        private List<CompletionItem> completionItems;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Completion item
    // ─────────────────────────────────────────────────────────────────────────
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class CompletionItem {
        private String  label;
        private boolean completed;
        private int     weight;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Vehicle sub-object
    // ─────────────────────────────────────────────────────────────────────────
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class VehicleInfo {
        private Long   id;
        private String vehicleType;   // "Car" | "Motorcycle"
        private String licensePlate;
        private String cardNumber;
        private String status;        // "ACTIVE" | "INACTIVE"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PUT /api/v1/profile/{userId}  →  UpdateRequest
    // ─────────────────────────────────────────────────────────────────────────
    @Data @NoArgsConstructor @AllArgsConstructor
    public static class UpdateRequest {
        private String firstname;
        private String lastname;
        private String phone;
        private String dateOfBirth;          // "yyyy-MM-dd"
        private String gender;
        private String identityCard;
        private String emergencyContactName;
        private String emergencyContactPhone;
        private String emergencyContactRelationship;  // Spouse, Parent, Sibling, Friend, Other
        private String avatarUrl;            // Cloudinary URL
        private String apartmentType;
        private String ownershipStatus;
        private String moveInDate;
        // Preferences
        private String language;
        private Boolean emailNotifications;
        private Boolean pushNotifications;
        private String theme;
    }
}
