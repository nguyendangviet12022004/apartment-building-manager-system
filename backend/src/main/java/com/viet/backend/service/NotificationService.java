package com.viet.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.viet.backend.model.Notification;
import com.viet.backend.model.User;
import com.viet.backend.repository.NotificationRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public void sendNotification(Integer userId, String title, String content, Map<String, String> data) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String jsonData = null;
        try {
            if (data != null) {
                jsonData = objectMapper.writeValueAsString(data);
            }
        } catch (JsonProcessingException e) {
            jsonData = "{}";
        }

        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .content(content)
                .data(jsonData)
                .build();

        notificationRepository.save(notification);

        // Push to Firebase
        if (user.getFcmToken() != null && !user.getFcmToken().isEmpty()) {
            try {
                com.google.firebase.messaging.Notification fcmNotification = com.google.firebase.messaging.Notification
                        .builder()
                        .setTitle(title)
                        .setBody(content)
                        .build();

                Message message = Message.builder()
                        .setToken(user.getFcmToken())
                        .setNotification(fcmNotification)
                        .putAllData(data != null ? data : Map.of())
                        .build();

                String response = FirebaseMessaging.getInstance().send(message);
                System.out.println("Successfully sent FCM message: " + response);
            } catch (FirebaseMessagingException e) {
                System.err.println("Error sending FCM message: " + e.getMessage());
                // Optional: Handle invalid tokens (e.g. remove from DB if error is
                // UNREGISTERED)
            }
        }
    }

    public List<Notification> getUserNotifications(Integer userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public void markAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
        notification.setRead(true);
        notificationRepository.save(notification);
    }
}
