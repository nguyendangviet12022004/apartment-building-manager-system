package com.viet.backend.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentDTO {

    private Long id;
    private String apartmentCode;
    private Integer floor;
    private Double area;
    private String status;
    private boolean used;

    // Flattened từ Block (tránh lazy load serialization)
    private Long blockId;
    private String blockCode;

    // Flattened từ Resident → User
    private Long residentId;
    private String residentName;  // firstname + lastname
    private String residentEmail;
}