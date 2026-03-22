// lib/models/payment_history_model.dart

enum PaymentStatus {
  success,
  failed,
  pending,
  cancelled;

  // Chấp nhận cả String "SUCCESS" lẫn Map {"name":"SUCCESS"} từ Spring
  static PaymentStatus fromJson(dynamic raw) {
    String? s;
    if (raw is String) {
      s = raw;
    } else if (raw is Map) {
      // Spring đôi khi serialize enum thành {"name":"SUCCESS","ordinal":1}
      s = raw['name']?.toString() ?? raw.toString();
    } else {
      s = raw?.toString();
    }
    return switch (s?.toUpperCase()) {
      'SUCCESS' => PaymentStatus.success,
      'FAILED' => PaymentStatus.failed,
      'CANCELLED' => PaymentStatus.cancelled,
      _ => PaymentStatus.pending,
    };
  }

  String get label => switch (this) {
    PaymentStatus.success => 'Success',
    PaymentStatus.failed => 'Failed',
    PaymentStatus.cancelled => 'Cancelled',
    PaymentStatus.pending => 'Pending',
  };
}

class PaymentHistoryItem {
  final int id;
  final String txnRef;
  final String invoiceCode;
  final int? invoiceId;
  final String invoiceMonth;
  final double amount;
  final PaymentStatus status;
  final String? bankCode;
  final String? vnpayTransactionNo;
  final String? vnpayResponseCode;
  final DateTime? createdAt;
  final DateTime? paidAt;

  PaymentHistoryItem({
    required this.id,
    required this.txnRef,
    required this.invoiceCode,
    this.invoiceId,
    required this.invoiceMonth,
    required this.amount,
    required this.status,
    this.bankCode,
    this.vnpayTransactionNo,
    this.vnpayResponseCode,
    this.createdAt,
    this.paidAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> j) {
    return PaymentHistoryItem(
      id: _parseInt(j['id']),
      txnRef: _str(j['txnRef']),
      invoiceCode: _str(j['invoiceCode']),
      invoiceId: j['invoiceId'] != null ? _parseInt(j['invoiceId']) : null,
      invoiceMonth: _str(j['invoiceMonth']),
      amount: _toDouble(j['amount']),
      status: PaymentStatus.fromJson(j['status']),
      bankCode: j['bankCode']?.toString(),
      vnpayTransactionNo: j['vnpayTransactionNo']?.toString(),
      vnpayResponseCode: j['vnpayResponseCode']?.toString(),
      createdAt: _parseDate(j['createdAt']),
      paidAt: _parseDate(j['paidAt']),
    );
  }
}

class PaymentHistorySummary {
  final int totalTransactions;
  final int successCount;
  final int failedCount;
  final double totalPaid;

  PaymentHistorySummary({
    required this.totalTransactions,
    required this.successCount,
    required this.failedCount,
    required this.totalPaid,
  });

  factory PaymentHistorySummary.fromJson(Map<String, dynamic> j) {
    return PaymentHistorySummary(
      totalTransactions: _parseInt(j['totalTransactions']),
      successCount: _parseInt(j['successCount']),
      failedCount: _parseInt(j['failedCount']),
      totalPaid: _toDouble(j['totalPaid']),
    );
  }
}

class PagedPaymentHistory {
  final List<PaymentHistoryItem> content;
  final int totalPages;
  final int totalElements;
  final int currentPage;
  final PaymentHistorySummary summary;

  PagedPaymentHistory({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
    required this.summary,
  });

  factory PagedPaymentHistory.fromJson(Map<String, dynamic> j) {
    // summary có thể null nếu BE chưa trả
    final rawSummary = j['summary'];
    final summary = rawSummary is Map<String, dynamic>
        ? PaymentHistorySummary.fromJson(rawSummary)
        : PaymentHistorySummary(
            totalTransactions: 0,
            successCount: 0,
            failedCount: 0,
            totalPaid: 0,
          );

    final rawContent = j['content'];
    final content = rawContent is List
        ? rawContent
              .whereType<Map<String, dynamic>>()
              .map(PaymentHistoryItem.fromJson)
              .toList()
        : <PaymentHistoryItem>[];

    return PagedPaymentHistory(
      content: content,
      totalPages: _parseInt(j['totalPages'], fallback: 1),
      totalElements: _parseInt(j['totalElements']),
      currentPage: _parseInt(j['currentPage'] ?? j['number']),
      summary: summary,
    );
  }
}

// ── Safe parse helpers ─────────────────────────────────────────────────────────
String _str(dynamic v) => v?.toString() ?? '';

int _parseInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is List) {
    // Spring đôi khi serialize LocalDateTime thành [2026,3,21,10,30,0]
    try {
      if (v.length >= 6) {
        return DateTime(v[0], v[1], v[2], v[3], v[4], v[5]);
      } else if (v.length >= 3) {
        return DateTime(v[0], v[1], v[2]);
      }
    } catch (_) {}
  }
  return null;
}
