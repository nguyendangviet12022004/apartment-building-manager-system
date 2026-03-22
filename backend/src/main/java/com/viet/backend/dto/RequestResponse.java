package com.viet.backend.dto;

import com.viet.backend.model.Request;
import com.viet.backend.model.RequestMedia;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestResponse {
    private Long id;
    private String title;
    private String description;
    private Request.RequestStatus status;
    private String issueType;
    private Request.Priority priority;
    private String location;
    private LocalDateTime occurrenceTime;
    private LocalDateTime createdAt;
    private LocalDateTime solvedBy;

    // Flattened AdminResponse for easier frontend consumption
    private String response;
    private LocalDateTime responseAt;
    private String adminName;

    private Integer userId;
    private String userEmail;
    private String userFullName;
    private List<MediaDto> media;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MediaDto {
        private String url;
        private RequestMedia.MediaType type;
    }

    public static RequestResponse fromEntity(Request request) {
        RequestResponseBuilder builder = RequestResponse.builder()
                .id(request.getId())
                .title(request.getTitle())
                .description(request.getDescription())
                .status(request.getStatus())
                .issueType(request.getIssueType())
                .priority(request.getPriority())
                .location(request.getLocation())
                .occurrenceTime(request.getOccurrenceTime())
                .createdAt(request.getCreatedAt())
                .solvedBy(request.getSolvedBy())
                .userId(request.getUser().getId())
                .userEmail(request.getUser().getEmail())
                .userFullName(request.getUser().getFirstname() + " " + request.getUser().getLastname())
                .media(request.getMedia().stream()
                        .map(m -> MediaDto.builder()
                                .url(m.getUrl())
                                .type(m.getMediaType())
                                .build())
                        .collect(Collectors.toList()));

        if (request.getAdminResponse() != null) {
            builder.response(request.getAdminResponse().getContent())
                    .responseAt(request.getAdminResponse().getRespondedAt());
            if (request.getAdminResponse().getAdmin() != null) {
                builder.adminName(request.getAdminResponse().getAdmin().getFirstname() + " " +
                        request.getAdminResponse().getAdmin().getLastname());
            }
        }

        return builder.build();
    }
}
