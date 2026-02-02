package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "residents")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Resident {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    private String identityCard;
    private String emergencyContact;
}
