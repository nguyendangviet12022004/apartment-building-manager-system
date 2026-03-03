package com.viet.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BlockRequest {
    @NotBlank(message = "Block code is required")
    @Size(min = 3, max = 3, message = "Block code must be exactly 3 characters")
    @Pattern(regexp = "^[A-Z0-9]{3}$", message = "Block code must be exactly 3 uppercase alphanumeric characters")
    private String blockCode;

    @Size(max = 255, message = "Description cannot exceed 255 characters")
    private String description;
}
