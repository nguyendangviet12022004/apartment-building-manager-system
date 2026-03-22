package com.viet.backend.controller;

import com.viet.backend.dto.ReminderDTO;
import com.viet.backend.service.ReminderEventService;
import com.viet.backend.service.ReminderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/reminders")
@RequiredArgsConstructor
public class ReminderController {

    private final ReminderService      reminderService;
    private final ReminderEventService eventService;

    /**
     * Flutter subscribe SSE stream để nhận kết quả real-time.
     * GET /api/v1/reminders/events?managerId=5
     *
     * Flutter giữ connection này mở suốt khi ở màn hình detail.
     */
    @GetMapping(value = "/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribeEvents(@RequestParam Integer managerId) {
        return eventService.subscribe(managerId);
    }

    /**
     * POST /api/v1/reminders/send
     * Trả về 202 Accepted NGAY, gửi FCM/email nền (@Async).
     * Khi xong → push SSE event "REMINDER_RESULT" về Flutter.
     *
     * Body: { "apartmentId":1, "sendPush":true, "sendEmail":true,
     *         "customMessage":null, "managerId":5 }
     */
    @PostMapping("/send")
    public ResponseEntity<ReminderDTO.Accepted> send(
            @RequestBody Map<String, Object> body) {

        Long    apartmentId   = Long.valueOf(body.get("apartmentId").toString());
        boolean sendPush      = Boolean.parseBoolean(body.getOrDefault("sendPush",  "false").toString());
        boolean sendEmail     = Boolean.parseBoolean(body.getOrDefault("sendEmail", "false").toString());
        String  customMessage = (String) body.getOrDefault("customMessage", null);
        Integer managerId     = Integer.valueOf(body.getOrDefault("managerId", "0").toString());

        ReminderDTO.Request req = new ReminderDTO.Request(
                apartmentId, sendPush, sendEmail, customMessage);

        // Kick off async — không block
        reminderService.sendReminderAsync(req, managerId);

        return ResponseEntity.accepted().body(
                ReminderDTO.Accepted.builder()
                        .message("Reminder queued")
                        .apartmentId(apartmentId)
                        .pushQueued(sendPush)
                        .emailQueued(sendEmail)
                        .build());
    }
}