package com.viet.backend.dto;

import lombok.*;

public class ReminderDTO {

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class Request {
        private Long   apartmentId;
        private boolean sendPush;
        private boolean sendEmail;
        private String  customMessage; // null → template mặc định
    }

    // Trả về ngay lập tức (không chờ gửi xong)
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Accepted {
        private String  message;     // "Reminder queued"
        private Long    apartmentId;
        private boolean pushQueued;
        private boolean emailQueued;
    }

    // Kết quả thực tế — gửi qua SSE về FE khi hoàn tất
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Result {
        private boolean pushSent;
        private boolean emailSent;
        private String  pushError;
        private String  emailError;
        private String  residentName;
        // SSE event type
        private String  eventType;   // "REMINDER_RESULT"
    }
}