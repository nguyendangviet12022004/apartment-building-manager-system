package com.viet.backend.controller;

import com.viet.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/test-notifications")
@RequiredArgsConstructor
public class TestNotificationController {

    private final NotificationService notificationService;

    @PostMapping("/send")
    public ResponseEntity<String> sendTestNotification(
            @RequestHeader("X-User-ID") Integer userId,
            @RequestParam String title,
            @RequestParam String content,
            @RequestParam(required = false) String detail) {

        notificationService.sendNotification(userId, title, content, detail,
                Map.of("click_action", "FLUTTER_NOTIFICATION_CLICK"));
        return ResponseEntity.ok("Test notification sent and saved");
    }

    @GetMapping("/user")
    public ResponseEntity<?> getUserNotifications(@RequestHeader("X-User-ID") Integer userId) {
        return ResponseEntity.ok(notificationService.getUserNotifications(userId));
    }

    @PostMapping("/mark-all-read")
    public ResponseEntity<String> markAllRead(@RequestHeader("X-User-ID") Integer userId) {
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok("All notifications marked as read");
    }
}
