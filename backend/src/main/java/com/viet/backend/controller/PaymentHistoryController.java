package com.viet.backend.controller;

import com.viet.backend.dto.PaymentHistoryDTO;
import com.viet.backend.service.PaymentHistoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/payment-history")
@RequiredArgsConstructor
public class PaymentHistoryController {

    private final PaymentHistoryService paymentHistoryService;

    // GET /api/v1/payment-history?apartmentId=2&page=0&size=20
    @GetMapping
    public ResponseEntity<PaymentHistoryDTO.PagedResponse> getHistory(
            @RequestParam Long apartmentId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {

        var pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "createdAt"));
        return ResponseEntity.ok(
                paymentHistoryService.getHistory(apartmentId, pageable));
    }

    // GET /api/v1/payment-history/invoice/{invoiceId}
    @GetMapping("/invoice/{invoiceId}")
    public ResponseEntity<List<PaymentHistoryDTO.Item>> getByInvoice(
            @PathVariable Long invoiceId) {
        return ResponseEntity.ok(
                paymentHistoryService.getByInvoice(invoiceId));
    }

    // GET /api/v1/payment-history/{id}
    @GetMapping("/{id}")
    public ResponseEntity<PaymentHistoryDTO.Item> getTransaction(
            @PathVariable Long id) {
        return ResponseEntity.ok(
                paymentHistoryService.getTransaction(id));
    }
}