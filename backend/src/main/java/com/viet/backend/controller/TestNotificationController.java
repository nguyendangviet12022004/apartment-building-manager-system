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
            @RequestParam Integer userId,
            @RequestParam String title,
            @RequestParam String content) {

        notificationService.sendNotification(userId, title, content,
                Map.of("click_action", "FLUTTER_NOTIFICATION_CLICK"));
        return ResponseEntity.ok("Test notification sent and saved");
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserNotifications(@PathVariable Integer userId) {
        return ResponseEntity.ok(notificationService.getUserNotifications(userId));
    }
}
