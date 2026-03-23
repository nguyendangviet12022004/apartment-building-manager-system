package com.viet.backend.controller;

import com.viet.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @PostMapping("/send")
    public ResponseEntity<String> sendNotification(
            @RequestParam(required = false) Integer userId,
            @RequestParam String title,
            @RequestParam String content,
            @RequestParam(required = false) String detail,
            @RequestParam(defaultValue = "false") boolean toAll) {

        Map<String, String> data = Map.of("click_action", "FLUTTER_NOTIFICATION_CLICK");

        if (toAll) {
            notificationService.sendToAll(title, content, detail, data);
        } else if (userId != null) {
            notificationService.sendNotification(userId, title, content, detail, data);
        } else {
            return ResponseEntity.badRequest().body("Either userId must be provided or toAll must be true");
        }
        
        return ResponseEntity.ok("Notification sent and saved");
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
