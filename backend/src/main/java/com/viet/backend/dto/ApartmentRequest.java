package com.viet.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentRequest {
    @NotBlank(message = "Apartment code is required")
    private String apartmentCode;

    @NotNull(message = "Floor is required")
    @Positive(message = "Floor must be positive")
    private Integer floor;

    @NotNull(message = "Area is required")
    @Positive(message = "Area must be positive")
    private Double area;

    @NotBlank(message = "Status is required")
    private String status;

    @NotNull(message = "Block ID is required")
    private Long blockId;
}
