package com.viet.backend.service;

import com.viet.backend.dto.RequestResponse;
import com.viet.backend.model.AdminResponse;
import com.viet.backend.model.Request;
import com.viet.backend.model.RequestMedia;
import com.viet.backend.model.User;
import com.viet.backend.repository.RequestRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RequestService {

    private final RequestRepository requestRepository;
    private final UserRepository userRepository;
    private final CloudinaryService cloudinaryService;

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB limit

    public Page<RequestResponse> getAllRequests(Request.RequestStatus status, Pageable pageable) {
        Specification<Request> spec = (root, query, criteriaBuilder) -> {
            if (status == null) {
                return null;
            }
            return criteriaBuilder.equal(root.get("status"), status);
        };

        return requestRepository.findAll(spec, pageable)
                .map(RequestResponse::fromEntity);
    }

    public Page<RequestResponse> getUserRequests(Integer userId, Pageable pageable) {
        return requestRepository.findAllByUserId(userId, pageable)
                .map(RequestResponse::fromEntity);
    }

    @Transactional
    public RequestResponse createRequest(Integer userId, String title, String description, List<MultipartFile> files) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Request request = Request.builder()
                .user(user)
                .title(title)
                .description(description)
                .status(Request.RequestStatus.PENDING)
                .createdAt(LocalDateTime.now())
                .media(new ArrayList<>())
                .build();

        if (files != null && !files.isEmpty()) {
            for (MultipartFile file : files) {
                if (file.getSize() > MAX_FILE_SIZE) {
                    throw new RuntimeException("File size exceeds limit of 10MB: " + file.getOriginalFilename());
                }

                String url = cloudinaryService.uploadFile(file, "requests");
                RequestMedia.MediaType type = determineMediaType(file);

                RequestMedia media = RequestMedia.builder()
                        .url(url)
                        .mediaType(type)
                        .request(request)
                        .build();
                request.getMedia().add(media);
            }
        }

        return RequestResponse.fromEntity(requestRepository.save(request));
    }

    private RequestMedia.MediaType determineMediaType(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null && contentType.startsWith("video/")) {
            return RequestMedia.MediaType.VIDEO;
        }
        return RequestMedia.MediaType.IMAGE;
    }

    @Transactional
    public RequestResponse updateStatus(Long requestId, Integer adminId, Request.RequestStatus status,
            String responseContent) {
        Request request = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin user not found"));

        request.setStatus(status);

        // Create or update AdminResponse entity
        AdminResponse adminResponse = request.getAdminResponse();
        if (adminResponse == null) {
            adminResponse = AdminResponse.builder()
                    .request(request)
                    .build();
            request.setAdminResponse(adminResponse);
        }

        adminResponse.setContent(responseContent);
        adminResponse.setRespondedAt(LocalDateTime.now());
        adminResponse.setAdmin(admin);

        return RequestResponse.fromEntity(requestRepository.save(request));
    }

    @Transactional
    public RequestResponse setTimeline(Long requestId, LocalDateTime solvedBy) {
        Request request = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (request.getStatus() != Request.RequestStatus.PENDING) {
            throw new RuntimeException("Timeline can only be set for PENDING requests");
        }

        if (solvedBy.isBefore(request.getCreatedAt())) {
            throw new RuntimeException("Solved by date cannot be before request creation date");
        }

        request.setSolvedBy(solvedBy);
        return RequestResponse.fromEntity(requestRepository.save(request));
    }
}
