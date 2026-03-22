package com.viet.backend.service;

import com.viet.backend.dto.UserProfileDTO;
import com.viet.backend.model.User;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service layer for User Profile operations
 * Handles business logic for retrieving and managing user profile information
 * 
 * @author Apartment Building Manager System
 * @version 1.0
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserProfileService {

    private final UserRepository userRepository;

    /**
     * Retrieves user profile by user ID
     * 
     * @param userId The unique identifier of the user
     * @return UserProfileDTO containing user profile information
     * @throws UsernameNotFoundException if user is not found
     */
    @Transactional(readOnly = true)
    public UserProfileDTO getUserProfile(Integer userId) {
        log.info("Fetching user profile for userId: {}", userId);
        
        // Fetch user from database
        User user = userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.error("User not found with id: {}", userId);
                    return new UsernameNotFoundException("User not found with id: " + userId);
                });

        // Convert entity to DTO
        UserProfileDTO profile = mapToDTO(user);
        
        log.info("Successfully retrieved profile for user: {}", user.getEmail());
        return profile;
    }

    /**
     * Retrieves user profile by email address
     * 
     * @param email The email address of the user
     * @return UserProfileDTO containing user profile information
     * @throws UsernameNotFoundException if user is not found
     */
    @Transactional(readOnly = true)
    public UserProfileDTO getUserProfileByEmail(String email) {
        log.info("Fetching user profile for email: {}", email);
        
        // Fetch user from database by email
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found with email: {}", email);
                    return new UsernameNotFoundException("User not found with email: " + email);
                });

        // Convert entity to DTO
        UserProfileDTO profile = mapToDTO(user);
        
        log.info("Successfully retrieved profile for user: {}", email);
        return profile;
    }

    /**
     * Maps User entity to UserProfileDTO
     * Handles null values and computes derived fields
     * 
     * @param user The User entity to map
     * @return UserProfileDTO with mapped data
     */
    private UserProfileDTO mapToDTO(User user) {
        // Safely get firstname and lastname
        String firstname = user.getFirstname() != null ? user.getFirstname() : "";
        String lastname = user.getLastname() != null ? user.getLastname() : "";
        
        // Compute full name
        String fullName = (firstname + " " + lastname).trim();
        if (fullName.isEmpty()) {
            fullName = user.getEmail(); // Fallback to email if no name
        }
        
        // Compute initials (e.g., "John Doe" -> "JD")
        String initials = computeInitials(firstname, lastname);
        
        // Build and return DTO
        return UserProfileDTO.builder()
                .id(user.getId())
                .firstname(firstname)
                .lastname(lastname)
                .fullName(fullName)
                .email(user.getEmail())
                .phone(null) // Phone not in User entity yet
                .role(user.getRole() != null ? user.getRole().name() : "UNKNOWN")
                .initials(initials)
                .build();
    }

    /**
     * Computes user initials from first and last name
     * 
     * @param firstname User's first name
     * @param lastname User's last name
     * @return Initials in uppercase (e.g., "JD")
     */
    private String computeInitials(String firstname, String lastname) {
        StringBuilder initials = new StringBuilder();
        
        // Add first letter of firstname
        if (firstname != null && !firstname.isEmpty()) {
            initials.append(firstname.charAt(0));
        }
        
        // Add first letter of lastname
        if (lastname != null && !lastname.isEmpty()) {
            initials.append(lastname.charAt(0));
        }
        
        // Return uppercase initials, or "U" as default
        return initials.length() > 0 ? initials.toString().toUpperCase() : "U";
    }
}
