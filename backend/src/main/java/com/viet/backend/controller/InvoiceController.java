package com.viet.backend.controller;

import com.viet.backend.dto.InvoiceDTO;
import com.viet.backend.model.Invoice.InvoiceStatus;
import com.viet.backend.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/invoices")
@RequiredArgsConstructor
public class InvoiceController {

    private final InvoiceService invoiceService;

    // ────────────────────────────────────────────────────
    // GET /api/v1/invoices/summary?apartmentId=1
    // → Summary card data (unpaid count, total outstanding…)
    // ────────────────────────────────────────────────────
    @GetMapping("/summary")
    public ResponseEntity<InvoiceDTO.Summary> summary(
            @RequestParam Long apartmentId) {
        return ResponseEntity.ok(invoiceService.getSummary(apartmentId));
    }

    // ────────────────────────────────────────────────────
    // GET /api/v1/invoices?apartmentId=1&status=UNPAID&page=0&size=10
    // → Paginated list (Flutter scrollable bill list)
    // ────────────────────────────────────────────────────
    @GetMapping
    public ResponseEntity<Page<InvoiceDTO.Response>> list(
            @RequestParam Long apartmentId,
            @RequestParam(required = false) InvoiceStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Pageable pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "dueDate"));
        return ResponseEntity.ok(invoiceService.list(apartmentId, status, pageable));
    }

    // ────────────────────────────────────────────────────
    // GET /api/v1/invoices/{id}
    // ────────────────────────────────────────────────────
    @GetMapping("/{id}")
    public ResponseEntity<InvoiceDTO.Response> getOne(@PathVariable Long id) {
        return ResponseEntity.ok(invoiceService.getById(id));
    }

    // Poll từ Flutter để kiểm tra trạng thái sau khi user dùng app ngân hàng
    @GetMapping("/code/{invoiceCode}")
    public ResponseEntity<InvoiceDTO.Response> getByCode(
            @PathVariable String invoiceCode) {
        return ResponseEntity.ok(invoiceService.getByCode(invoiceCode));
    }

    // ────────────────────────────────────────────────────
    // POST /api/v1/invoices
    // ────────────────────────────────────────────────────
    @PostMapping
    public ResponseEntity<InvoiceDTO.Response> create(
            @RequestBody InvoiceDTO.Request req) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(invoiceService.create(req));
    }

    // ────────────────────────────────────────────────────
    // PUT /api/v1/invoices/{id}
    // ────────────────────────────────────────────────────
//    @PutMapping("/{id}")
//    public ResponseEntity<InvoiceDTO.Response> update(
//            @PathVariable Long id,
//            @RequestBody InvoiceDTO.Request req) {
//        return ResponseEntity.ok(invoiceService.update(id, req));
//    }

    // ────────────────────────────────────────────────────
    // PATCH /api/v1/invoices/{id}/status
    // → "Pay Now" button in Flutter calls this
    // Body: { "status": "PAID" }
    // ────────────────────────────────────────────────────
    @PatchMapping("/{id}/status")
    public ResponseEntity<InvoiceDTO.Response> updateStatus(
            @PathVariable Long id,
            @RequestBody InvoiceDTO.StatusUpdate req) {
        return ResponseEntity.ok(invoiceService.updateStatus(id, req));
    }

    // ── Manager endpoints ────────────────────────────────
    // GET /api/v1/invoices/manager?status=overdue&search=A501&page=0&size=20
    @GetMapping("/manager")
    public ResponseEntity<org.springframework.data.domain.Page<InvoiceDTO.ManagerListItem>> managerList(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(invoiceService.managerList(status, search, pageable));
    }

    // GET /api/v1/invoices/manager/summary
    @GetMapping("/manager/summary")
    public ResponseEntity<InvoiceDTO.ManagerSummary> managerSummary() {
        return ResponseEntity.ok(invoiceService.managerSummary());
    }

    // GET /api/v1/invoices/manager/apartment/{apartmentId}
    @GetMapping("/manager/apartment/{apartmentId}")
    public ResponseEntity<InvoiceDTO.ManagerDetail> managerDetail(
            @PathVariable Long apartmentId) {
        return ResponseEntity.ok(invoiceService.managerDetail(apartmentId));
    }

    // ────────────────────────────────────────────────────
    // DELETE /api/v1/invoices/{id}
    // ────────────────────────────────────────────────────
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> delete(@PathVariable Long id) {
        invoiceService.delete(id);
        return ResponseEntity.ok(Map.of("message", "Invoice deleted successfully"));
    }
}