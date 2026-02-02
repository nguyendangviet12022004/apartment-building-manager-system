package com.viet.backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "blocks")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Block {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String blockCode;

    private String description;
}
