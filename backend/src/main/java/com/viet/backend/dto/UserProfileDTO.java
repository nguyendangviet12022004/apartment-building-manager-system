package com.viet.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for User Profile Response
 * Used to transfer user profile data without exposing sensitive information
 * Follows DTO pattern to separate API response from internal entity structure
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileDTO {

    /**
     * User's unique identifier
     */
    private Integer id;

    /**
     * User's first name
     */
    private String firstname;

    /**
     * User's last name
     */
    private String lastname;

    /**
     * User's full name (computed from firstname + lastname)
     */
    private String fullName;

    /**
     * User's email address
     */
    private String email;

    /**
     * User's phone number (if available)
     * Note: Currently not in User entity, will return null
     */
    private String phone;

    /**
     * User's role in the system (RESIDENT, MANAGER, ADMIN)
     */
    private String role;

    /**
     * User's initials for avatar display (e.g., "JD" for John Doe)
     */
    private String initials;
}
