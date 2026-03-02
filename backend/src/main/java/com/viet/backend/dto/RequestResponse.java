package com.viet.backend.dto;

import com.viet.backend.model.Request;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestResponse {
    private Long id;
    private String title;
    private String description;
    private Request.RequestStatus status;
    private LocalDateTime createdAt;
    private String response;
    private LocalDateTime responseAt;
    private Integer userId;
    private String userEmail;
    private String userFullName;

    public static RequestResponse fromEntity(Request request) {
        return RequestResponse.builder()
                .id(request.getId())
                .title(request.getTitle())
                .description(request.getDescription())
                .status(request.getStatus())
                .createdAt(request.getCreatedAt())
                .response(request.getResponse())
                .responseAt(request.getResponseAt())
                .userId(request.getUser().getId())
                .userEmail(request.getUser().getEmail())
                .userFullName(request.getUser().getFirstname() + " " + request.getUser().getLastname())
                .build();
    }
}
