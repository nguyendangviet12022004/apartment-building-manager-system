package com.viet.backend.controller;

import com.viet.backend.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/payment")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService payService;

    // Flutter gọi để lấy URL → mở WebView
    // POST /api/v1/payment/create?invoiceId=5
    @PostMapping("/create")
    public ResponseEntity<Map<String, String>> createPayment(
            @RequestParam Long invoiceId,
            HttpServletRequest req) {
        return ResponseEntity.ok(payService.createPaymentUrl(invoiceId, req));
    }

    // Flutter gửi lên params từ deep link sau khi thanh toán
    // BE verify chữ ký + update invoice status
    @PostMapping("/verify")
    public ResponseEntity<Map<String, String>> verify(
            @RequestBody Map<String, String> params) {
        return ResponseEntity.ok(payService.verifyAndUpdate(params));
    }
}