package com.viet.backend.dto;

import com.viet.backend.model.Apartment;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ApartmentResponse {
    private Long id;
    private String apartmentCode;
    private Integer floor;
    private Double area;
    private String status;
    private boolean used;
    private Long blockId;
    private String blockCode;

    public static ApartmentResponse fromEntity(Apartment apartment) {
        return ApartmentResponse.builder()
                .id(apartment.getId())
                .apartmentCode(apartment.getApartmentCode())
                .floor(apartment.getFloor())
                .area(apartment.getArea())
                .status(apartment.getStatus())
                .used(apartment.isUsed())
                .blockId(apartment.getBlock() != null ? apartment.getBlock().getId() : null)
                .blockCode(apartment.getBlock() != null ? apartment.getBlock().getBlockCode() : null)
                .build();
    }
}
