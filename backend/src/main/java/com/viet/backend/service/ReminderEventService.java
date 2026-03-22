package com.viet.backend.service;

import com.viet.backend.dto.ReminderDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class ReminderEventService {

    private final Map<Integer, SseEmitter> emitters = new ConcurrentHashMap<>();

    public SseEmitter subscribe(Integer managerId) {
        // Long timeout — Flutter sẽ reconnect nếu bị ngắt
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);

        // Xóa emitter cũ nếu có
        SseEmitter old = emitters.put(managerId, emitter);
        if (old != null) {
            try { old.complete(); } catch (Exception ignored) {}
        }

        emitter.onCompletion(() -> {
            log.debug("SSE completed for manager {}", managerId);
            emitters.remove(managerId, emitter);
        });
        emitter.onTimeout(() -> {
            log.debug("SSE timeout for manager {}", managerId);
            emitters.remove(managerId, emitter);
        });
        emitter.onError(e -> {
            log.debug("SSE error for manager {}: {}", managerId, e.getMessage());
            emitters.remove(managerId, emitter);
        });

        // Gửi connected event ngay
        try {
            emitter.send(SseEmitter.event()
                    .name("connected")
                    .data("ok"));
        } catch (IOException e) {
            emitters.remove(managerId, emitter);
        }

        return emitter;
    }

    // Heartbeat mỗi 20s để giữ kết nối không bị proxy/firewall cắt
    @Scheduled(fixedDelay = 20_000)
    public void sendHeartbeat() {
        emitters.forEach((managerId, emitter) -> {
            try {
                emitter.send(SseEmitter.event()
                        .name("heartbeat")
                        .data(System.currentTimeMillis()));
            } catch (IOException e) {
                log.debug("Heartbeat failed for manager {}, removing", managerId);
                emitters.remove(managerId, emitter);
            }
        });
    }

    public void pushResult(Integer managerId, ReminderDTO.Result result) {
        SseEmitter emitter = emitters.get(managerId);
        if (emitter == null) {
            log.warn("No SSE emitter for managerId={}", managerId);
            return;
        }
        try {
            emitter.send(SseEmitter.event()
                    .name("REMINDER_RESULT")
                    .data(result));
            log.info("SSE REMINDER_RESULT pushed to manager {}", managerId);
        } catch (IOException e) {
            log.error("SSE push failed for manager {}: {}", managerId, e.getMessage());
            emitters.remove(managerId, emitter);
        }
    }
}