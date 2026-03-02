package com.viet.backend.service;

import com.viet.backend.dto.RequestResponse;
import com.viet.backend.model.Request;
import com.viet.backend.model.User;
import com.viet.backend.repository.RequestRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class RequestService {

    private final RequestRepository requestRepository;
    private final UserRepository userRepository;

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
    public RequestResponse createRequest(Integer userId, String title, String description) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Request request = Request.builder()
                .user(user)
                .title(title)
                .description(description)
                .status(Request.RequestStatus.PENDING)
                .createdAt(LocalDateTime.now())
                .build();

        return RequestResponse.fromEntity(requestRepository.save(request));
    }

    @Transactional
    public RequestResponse updateStatus(Long requestId, Request.RequestStatus status, String response) {
        Request request = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        request.setStatus(status);
        request.setResponse(response);
        request.setResponseAt(LocalDateTime.now());

        return RequestResponse.fromEntity(requestRepository.save(request));
    }
}
