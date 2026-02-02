package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "resident_apartment")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ResidentApartment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id")
    private Resident resident;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id")
    private Apartment apartment;

    private String relationship; // e.g., Owner, Renter, Member
    private LocalDateTime startDate;
}
