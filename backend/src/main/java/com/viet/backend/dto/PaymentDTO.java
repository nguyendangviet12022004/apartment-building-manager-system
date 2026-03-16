package com.viet.backend.dto;

import lombok.*;

public class PaymentDTO {

    // Request từ Flutter: tạo URL thanh toán
    @Data @NoArgsConstructor @AllArgsConstructor
    public static class CreateRequest {
        private Long invoiceId;
        private String clientIp; // IP của client, Flutter gửi lên
    }

    // Response trả về Flutter: chứa URL để mở WebView/browser
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class CreateResponse {
        private String paymentUrl;
        private String txnRef;    // mã giao dịch để tra cứu
    }

    // Kết quả sau khi VNPAY redirect về (dùng cho deep link)
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class Result {
        private boolean success;
        private String message;
        private Long invoiceId;
        private String txnRef;
        private String transactionNo; // mã GD phía VNPAY
    }
}