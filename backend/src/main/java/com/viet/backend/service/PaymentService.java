package com.viet.backend.service;

import com.viet.backend.config.VNPayConfig;
import com.viet.backend.model.Invoice;
import com.viet.backend.model.PaymentTransaction;
import com.viet.backend.repository.InvoiceRepository;
import com.viet.backend.repository.PaymentTransactionRepository;
import com.viet.backend.util.VNPayUtil;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final InvoiceRepository invoiceRepository;
    private final PaymentTransactionRepository txnRepository;

    // ── Tạo URL thanh toán ────────────────────────────────────────────────────
    public Map<String, String> createPaymentUrl(Long invoiceId, HttpServletRequest req) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Invoice not found: " + invoiceId));

        // VNPay yêu cầu amount * 100 (VND, không có decimal)
        long amount = invoice.getTotal().multiply(BigDecimal.valueOf(100)).longValue();

        String txnRef = invoice.getInvoiceCode(); // unique per invoice

        // Tạo / cập nhật transaction về PENDING
        PaymentTransaction txn = txnRepository.findByTxnRef(txnRef)
                .orElseGet(() -> PaymentTransaction.builder()
                        .txnRef(txnRef)
                        .invoice(invoice)
                        .amount(invoice.getTotal().longValue())
                        .build());

        txn.setStatus(PaymentTransaction.TxnStatus.PENDING);
        txn.setPaidAt(null);
        txnRepository.save(txn);

        TimeZone tz = TimeZone.getTimeZone(VNPayConfig.TIMEZONE);
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
        sdf.setTimeZone(tz);
        String createDate = sdf.format(new Date());
        String expireDate = sdf.format(new Date(System.currentTimeMillis() + 15 * 60 * 1000));

        Map<String, String> params = new LinkedHashMap<>();
        params.put("vnp_Version", VNPayConfig.VERSION);
        params.put("vnp_Command", VNPayConfig.COMMAND);
        params.put("vnp_TmnCode", VNPayConfig.TMN_CODE);
        params.put("vnp_Amount", String.valueOf(amount));
        params.put("vnp_CurrCode", VNPayConfig.CURR_CODE);
        params.put("vnp_TxnRef", txnRef);
        params.put("vnp_OrderInfo", "Thanh toan hoa don " + txnRef);
        params.put("vnp_OrderType", VNPayConfig.ORDER_TYPE);
        params.put("vnp_Locale", VNPayConfig.LOCALE);
        params.put("vnp_ReturnUrl", VNPayConfig.RETURN_URL);
        params.put("vnp_IpAddr", VNPayUtil.getIpAddr(req));
        params.put("vnp_CreateDate", createDate);
        params.put("vnp_ExpireDate", expireDate);

        String hashData = VNPayUtil.buildHashData(params);
        String signature = VNPayUtil.hmacSHA512(VNPayConfig.HASH_SECRET, hashData);

        String queryString = VNPayUtil.buildQueryString(params) + "&vnp_SecureHash=" + signature;
        String paymentUrl = VNPayConfig.PAY_URL + "?" + queryString;

        return Map.of(
                "paymentUrl", paymentUrl,
                "txnRef", txnRef,
                "invoiceId", String.valueOf(invoiceId)
        );
    }

    // ── Flutter gửi params lên sau khi WebView bắt được deep link ────────────
    // BE verify chữ ký và update status — không cần public URL
    @Transactional
    public Map<String, String> verifyAndUpdate(Map<String, String> params) {
        String receivedHash = params.get("vnp_SecureHash");
        String responseCode = params.get("vnp_ResponseCode");
        String txnRef = params.get("vnp_TxnRef");

        if (receivedHash == null || txnRef == null) {
            return Map.of("code", "99", "message", "missing_params");
        }

        // Build hash để verify (bỏ vnp_SecureHash và vnp_SecureHashType)
        Map<String, String> verifyParams = new TreeMap<>(params);
        verifyParams.remove("vnp_SecureHash");
        verifyParams.remove("vnp_SecureHashType");

        String computedHash = VNPayUtil.hmacSHA512(
                VNPayConfig.HASH_SECRET,
                VNPayUtil.buildHashData(verifyParams));

        if (!computedHash.equalsIgnoreCase(receivedHash)) {
            return Map.of("code", "97", "message", "invalid_signature");
        }

        boolean success = "00".equals(responseCode);

        if (success) {
            // Update transaction → SUCCESS
            txnRepository.findByTxnRef(txnRef).ifPresent(txn -> {
                txn.setStatus(PaymentTransaction.TxnStatus.SUCCESS);
                txn.setTransactionNo(params.get("vnp_TransactionNo"));
                txn.setVnpResponseCode(responseCode);
                txn.setBankCode(params.get("vnp_BankCode"));
                txn.setCardType(params.get("vnp_CardType"));
                txn.setPaidAt(LocalDateTime.now());
                txnRepository.save(txn);
            });

            // Update invoice → PAID
            invoiceRepository.findByInvoiceCode(txnRef).ifPresent(inv -> {
                inv.setStatus(Invoice.InvoiceStatus.PAID);
                invoiceRepository.save(inv);
            });

            return Map.of("code", "00", "message", "success", "txnRef", txnRef);
        } else {
            _updateTxnStatus(txnRef, PaymentTransaction.TxnStatus.FAILED, params);
            return Map.of("code", responseCode, "message", "payment_failed");
        }
    }

    private void _updateTxnStatus(String txnRef, PaymentTransaction.TxnStatus status,
                                  Map<String, String> params) {
        txnRepository.findByTxnRef(txnRef).ifPresent(txn -> {
            txn.setStatus(status);
            txn.setVnpResponseCode(params.get("vnp_ResponseCode"));
            txn.setBankCode(params.get("vnp_BankCode"));
            txnRepository.save(txn);
        });
    }
}
