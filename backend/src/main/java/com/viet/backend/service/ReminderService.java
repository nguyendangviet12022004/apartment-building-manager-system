package com.viet.backend.service;

import com.google.firebase.messaging.*;
import com.viet.backend.dto.ReminderDTO;
import com.viet.backend.model.Invoice;
import com.viet.backend.model.Invoice.InvoiceStatus;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.InvoiceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReminderService {

    private final ApartmentRepository apartmentRepository;
    private final InvoiceRepository   invoiceRepository;
    private final JavaMailSender      mailSender;
    private final ReminderEventService eventService; // SSE push

    /**
     * @Async: HTTP response trả về NGAY ("queued"),
     * việc gửi FCM/email chạy nền trong thread pool.
     * Khi xong → push SSE về FE.
     */
    @Async
    @Transactional
    public void sendReminderAsync(ReminderDTO.Request req, Integer managerId) {
        ReminderDTO.Result result = doSend(req);
        result.setEventType("REMINDER_RESULT");
        // Đẩy kết quả về manager đang mở màn hình qua SSE
        eventService.pushResult(managerId, result);
    }

    // Phương thức đồng bộ — dùng khi cần (e.g. scheduled bulk)
    public ReminderDTO.Result sendReminder(ReminderDTO.Request req) {
        return doSend(req);
    }

    @Transactional(readOnly = true)
    ReminderDTO.Result doSend(ReminderDTO.Request req) {
        // Dùng eager fetch — tránh LazyInitializationException trong @Async thread
        var apt = apartmentRepository.findByIdWithResident(req.getApartmentId())
                .orElseThrow(() -> new RuntimeException(
                        "Apartment not found: " + req.getApartmentId()));

        String residentName  = "Resident";
        String residentEmail = null;
        String fcmToken      = null;

        if (apt.getResident() != null && apt.getResident().getUser() != null) {
            var user     = apt.getResident().getUser();
            residentName  = user.getFirstname() + " " + user.getLastname();
            residentEmail = user.getEmail();
            fcmToken      = user.getFcmToken();
        }

        BigDecimal totalDebt = invoiceRepository.sumOutstanding(apt.getId());
        if (totalDebt == null) totalDebt = BigDecimal.ZERO;

        List<Invoice> outstanding = invoiceRepository.findAllByApartmentId(apt.getId())
                .stream()
                .filter(i -> i.getStatus() == InvoiceStatus.UNPAID
                        || i.getStatus() == InvoiceStatus.OVERDUE)
                .collect(Collectors.toList());

        String title   = "Payment Reminder — " + apt.getApartmentCode();
        String bodyMsg = (req.getCustomMessage() != null && !req.getCustomMessage().isBlank())
                ? req.getCustomMessage()
                : String.format(
                "Dear %s, you have %d outstanding invoice(s) totaling %sđ. Please pay to avoid late fees.",
                residentName, outstanding.size(), formatVnd(totalDebt));

        // ── FCM Push ──────────────────────────────────────────────────────────
        boolean pushSent  = false;
        String  pushError = null;

        if (req.isSendPush()) {
            if (fcmToken == null || fcmToken.isBlank()) {
                pushError = "No FCM token for this resident";
                log.warn("No FCM token for apartment {}", apt.getId());
            } else {
                try {
                    Message fcmMsg = Message.builder()
                            .setToken(fcmToken)
                            .setNotification(Notification.builder()
                                    .setTitle(title)
                                    .setBody(bodyMsg)
                                    .build())
                            .putData("type",        "INVOICE_REMINDER")
                            .putData("apartmentId", String.valueOf(apt.getId()))
                            .putData("totalDebt",   totalDebt.toPlainString())
                            .setAndroidConfig(AndroidConfig.builder()
                                    .setPriority(AndroidConfig.Priority.HIGH)
                                    .build())
                            .build();
                    String response = FirebaseMessaging.getInstance().send(fcmMsg);
                    log.info("FCM sent: {}", response);
                    pushSent = true;
                } catch (FirebaseMessagingException e) {
                    pushError = e.getMessage();
                    log.error("FCM error: {}", e.getMessage());
                }
            }
        }

        // ── Email ─────────────────────────────────────────────────────────────
        boolean emailSent  = false;
        String  emailError = null;

        if (req.isSendEmail()) {
            if (residentEmail == null || residentEmail.isBlank()) {
                emailError = "No email for this resident";
            } else {
                try {
                    var mime   = mailSender.createMimeMessage();
                    var helper = new MimeMessageHelper(mime, true, "UTF-8");
                    helper.setTo(residentEmail);
                    helper.setSubject(title);
                    helper.setText(buildEmailHtml(
                            residentName, apt.getApartmentCode(),
                            outstanding, totalDebt), true);
                    mailSender.send(mime);
                    emailSent = true;
                    log.info("Email sent to {}", residentEmail);
                } catch (Exception e) {
                    emailError = e.getMessage();
                    log.error("Email error: {}", e.getMessage());
                }
            }
        }

        return ReminderDTO.Result.builder()
                .pushSent(pushSent)
                .emailSent(emailSent)
                .pushError(pushError)
                .emailError(emailError)
                .residentName(residentName)
                .build();
    }

    // ── Email HTML template ───────────────────────────────────────────────────
    private String buildEmailHtml(String name, String aptCode,
                                  List<Invoice> invoices, BigDecimal total) {
        var fmt  = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        var rows = invoices.stream().map(inv -> String.format("""
                <tr>
                  <td style="padding:8px 12px;border-bottom:1px solid #f0f0f0">%s</td>
                  <td style="padding:8px 12px;border-bottom:1px solid #f0f0f0">%s</td>
                  <td style="padding:8px 12px;border-bottom:1px solid #f0f0f0;text-align:right;font-weight:700">%sđ</td>
                  <td style="padding:8px 12px;border-bottom:1px solid #f0f0f0">
                    <span style="background:%s;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px">%s</span>
                  </td>
                </tr>""",
                inv.getInvoiceCode(),
                inv.getDueDate() != null ? inv.getDueDate().format(fmt) : "—",
                formatVnd(inv.getTotal()),
                inv.getStatus() == InvoiceStatus.OVERDUE ? "#EF4444" : "#F59E0B",
                inv.getStatus().name()
        )).collect(Collectors.joining());

        return """
                <!DOCTYPE html>
                <html>
                <body style="font-family:'Segoe UI',Arial,sans-serif;background:#f5f5f5;margin:0;padding:20px">
                  <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)">
                    <div style="background:linear-gradient(135deg,#88304E,#522546);padding:28px 32px">
                      <h2 style="color:#fff;margin:0;font-size:20px">Payment Reminder</h2>
                      <p style="color:rgba(255,255,255,.75);margin:4px 0 0;font-size:13px">%s</p>
                    </div>
                    <div style="padding:28px 32px">
                      <p style="margin:0 0 6px;color:#374151;font-size:15px">Dear <strong>%s</strong>,</p>
                      <p style="margin:0 0 20px;color:#6B7280;font-size:14px;line-height:1.6">
                        You have outstanding invoices that require your attention.
                        Please settle them to avoid additional late fees.
                      </p>
                      <table width="100%%" style="border-collapse:collapse;font-size:13px">
                        <thead>
                          <tr style="background:#f9fafb">
                            <th style="padding:8px 12px;text-align:left;color:#6B7280;font-weight:600">Invoice</th>
                            <th style="padding:8px 12px;text-align:left;color:#6B7280;font-weight:600">Due Date</th>
                            <th style="padding:8px 12px;text-align:right;color:#6B7280;font-weight:600">Amount</th>
                            <th style="padding:8px 12px;text-align:left;color:#6B7280;font-weight:600">Status</th>
                          </tr>
                        </thead>
                        <tbody>%s</tbody>
                      </table>
                      <div style="margin-top:16px;background:#f9fafb;border-radius:10px;padding:14px 16px">
                        <span style="color:#374151;font-weight:700">Total Outstanding: </span>
                        <span style="color:#88304E;font-size:18px;font-weight:800">%sđ</span>
                      </div>
                    </div>
                    <div style="padding:16px 32px 28px;text-align:center">
                      <p style="color:#9CA3AF;font-size:12px;margin:0">
                        Automated reminder from Apartment Management System.
                      </p>
                    </div>
                  </div>
                </body>
                </html>
                """.formatted(aptCode, name, rows, formatVnd(total));
    }

    private String formatVnd(BigDecimal amount) {
        if (amount == null) return "0";
        String s   = amount.toBigInteger().toString();
        var    buf = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            if (i > 0 && (s.length() - i) % 3 == 0) buf.append('.');
            buf.append(s.charAt(i));
        }
        return buf.toString();
    }
}