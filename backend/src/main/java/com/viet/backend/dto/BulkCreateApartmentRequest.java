package com.viet.backend.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class BulkCreateApartmentRequest {

    @NotNull(message = "Block ID is required")
    private Long blockId;

    @NotNull(message = "Floor is required")
    @Min(value = 1, message = "Floor must be greater than 0")
    private Integer floor;

    @NotEmpty(message = "Units list cannot be empty")
    private List<ApartmentUnitRequest> units;

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ApartmentUnitRequest {
        @NotNull(message = "Area is required")
        @Min(value = 1, message = "Area must be greater than 0")
        private Double area;
    }
}
