package com.viet.backend.dto;

import jakarta.validation.constraints.NotBlank;
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
    @Size(min = 1, max = 50, message = "Block code must be between 1 and 50 characters")
    private String blockCode;

    @Size(max = 255, message = "Description cannot exceed 255 characters")
    private String description;
}
