// lib/models/invoice_model.dart

class InvoiceSummary {
  final int unpaidCount;
  final int paidCount;
  final int overdueCount;
  final double totalOutstanding;

  InvoiceSummary({
    required this.unpaidCount,
    required this.paidCount,
    required this.overdueCount,
    required this.totalOutstanding,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(
    unpaidCount: json['unpaidCount'] ?? 0,
    paidCount: json['paidCount'] ?? 0,
    overdueCount: json['overdueCount'] ?? 0,
    totalOutstanding: (json['totalOutstanding'] ?? 0).toDouble(),
  );
}

class Invoice {
  final int id;
  final String invoiceCode;
  final int? apartmentId;
  final String? apartmentCode;
  final double subtotal;
  final double lateFee;
  final double total;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final InvoiceStatus status;
  final int daysUntilDue;
  final List<String> serviceLabels;
  final List<InvoiceItem> items;
  // Apartment detail
  final int? apartmentFloor;
  final double? apartmentArea;
  final String? blockCode;
  final String? residentName;

  Invoice({
    required this.id,
    required this.invoiceCode,
    this.apartmentId,
    this.apartmentCode,
    required this.subtotal,
    required this.lateFee,
    required this.total,
    this.invoiceDate,
    this.dueDate,
    this.createdAt,
    required this.status,
    required this.daysUntilDue,
    required this.serviceLabels,
    this.items = const [],
    this.apartmentFloor,
    this.apartmentArea,
    this.blockCode,
    this.residentName,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'],
    invoiceCode: json['invoiceCode'] ?? '',
    apartmentId: json['apartmentId'],
    apartmentCode: json['apartmentCode'],
    subtotal: (json['subtotal'] ?? 0).toDouble(),
    lateFee: (json['lateFee'] ?? 0).toDouble(),
    total: (json['total'] ?? 0).toDouble(),
    invoiceDate: json['invoiceDate'] != null
        ? DateTime.parse(json['invoiceDate'])
        : null,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    status: InvoiceStatus.fromString(json['status']),
    daysUntilDue: json['daysUntilDue'] ?? 0,
    serviceLabels: List<String>.from(json['serviceLabels'] ?? []),
    items: (json['items'] as List? ?? [])
        .map((e) => InvoiceItem.fromJson(e))
        .toList(),
    apartmentFloor: json['apartmentFloor'],
    apartmentArea: json['apartmentArea'] != null
        ? (json['apartmentArea'] as num).toDouble()
        : null,
    blockCode: json['blockCode'],
    residentName: json['residentName'],
  );

  String get monthLabel {
    if (invoiceDate == null) return invoiceCode;
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[invoiceDate!.month]} ${invoiceDate!.year}';
  }

  String get dueLabel {
    if (dueDate == null) return '';
    final d = daysUntilDue;
    final dateStr = 'Due ${_monthShort(dueDate!.month)} ${dueDate!.day}';
    if (d < 0) return '$dateStr · ${-d} days overdue';
    if (d == 0) return '$dateStr · Due today';
    return '$dateStr · $d days left';
  }

  static String _monthShort(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

enum InvoiceStatus {
  unpaid,
  paid,
  overdue,
  cancelled;

  static InvoiceStatus fromString(String? s) => switch (s?.toUpperCase()) {
    'PAID' => InvoiceStatus.paid,
    'OVERDUE' => InvoiceStatus.overdue,
    'CANCELLED' => InvoiceStatus.cancelled,
    _ => InvoiceStatus.unpaid,
  };

  String get label => switch (this) {
    InvoiceStatus.paid => 'Paid',
    InvoiceStatus.overdue => 'Overdue',
    InvoiceStatus.cancelled => 'Cancelled',
    InvoiceStatus.unpaid => 'Unpaid',
  };
}

class InvoiceItem {
  final int? serviceId;
  final String serviceName;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceItem({
    this.serviceId,
    required this.serviceName,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    serviceId: json['serviceId'],
    serviceName: json['serviceName'] ?? '',
    unit: json['unit'],
    quantity: (json['quantity'] ?? 0).toDouble(),
    unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    amount: (json['amount'] ?? 0).toDouble(),
  );
}

/// Wrapper for paginated list response from Spring Boot
class PagedInvoice {
  final List<Invoice> content;
  final int totalPages;
  final int totalElements;
  final int number; // current page

  PagedInvoice({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
  });

  factory PagedInvoice.fromJson(Map<String, dynamic> json) => PagedInvoice(
    content: (json['content'] as List).map((e) => Invoice.fromJson(e)).toList(),
    totalPages: json['totalPages'] ?? 1,
    totalElements: json['totalElements'] ?? 0,
    number: json['number'] ?? 0,
  );
}
