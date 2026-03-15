// lib/models/manager_invoice_model.dart

import 'invoice_model.dart';

// Item trong danh sách apartments (invoice list)
class ManagerListItem {
  final int apartmentId;
  final String apartmentCode;
  final String? blockCode;
  final int? floor;
  final String residentName;
  final String residentEmail;
  final double totalDebt;
  final int unpaidCount;
  final int overdueCount;
  final int monthsOverdue;
  final String status; // "paid" | "unpaid" | "overdue"
  final String initials;

  ManagerListItem({
    required this.apartmentId,
    required this.apartmentCode,
    this.blockCode,
    this.floor,
    required this.residentName,
    required this.residentEmail,
    required this.totalDebt,
    required this.unpaidCount,
    required this.overdueCount,
    required this.monthsOverdue,
    required this.status,
    required this.initials,
  });

  factory ManagerListItem.fromJson(Map<String, dynamic> j) => ManagerListItem(
    apartmentId: j['apartmentId'],
    apartmentCode: j['apartmentCode'] ?? '',
    blockCode: j['blockCode'],
    floor: j['floor'],
    residentName: j['residentName'] ?? '',
    residentEmail: j['residentEmail'] ?? '',
    totalDebt: (j['totalDebt'] ?? 0).toDouble(),
    unpaidCount: j['unpaidCount'] ?? 0,
    overdueCount: j['overdueCount'] ?? 0,
    monthsOverdue: j['monthsOverdue'] ?? 0,
    status: j['status'] ?? 'unpaid',
    initials: j['initials'] ?? '?',
  );

  String get aptLabel {
    final parts = <String>[];
    if (blockCode != null) parts.add('Block $blockCode');
    if (floor != null) parts.add('Floor $floor');
    return parts.join(' · ');
  }
}

// Detail 1 apartment cho manager
class ManagerDetail {
  final int apartmentId;
  final String apartmentCode;
  final String? blockCode;
  final int? floor;
  final double? area;
  final String residentName;
  final String residentEmail;
  final String? residentPhone;
  final String? contractStart;
  final String? contractEnd;
  final double totalOutstanding;
  final List<Invoice> outstandingInvoices;
  final List<Invoice> paidInvoices;

  ManagerDetail({
    required this.apartmentId,
    required this.apartmentCode,
    this.blockCode,
    this.floor,
    this.area,
    required this.residentName,
    required this.residentEmail,
    this.residentPhone,
    this.contractStart,
    this.contractEnd,
    required this.totalOutstanding,
    required this.outstandingInvoices,
    required this.paidInvoices,
  });

  factory ManagerDetail.fromJson(Map<String, dynamic> j) => ManagerDetail(
    apartmentId: j['apartmentId'],
    apartmentCode: j['apartmentCode'] ?? '',
    blockCode: j['blockCode'],
    floor: j['floor'],
    area: j['area'] != null ? (j['area'] as num).toDouble() : null,
    residentName: j['residentName'] ?? '',
    residentEmail: j['residentEmail'] ?? '',
    residentPhone: j['residentPhone'],
    contractStart: j['contractStart'],
    contractEnd: j['contractEnd'],
    totalOutstanding: (j['totalOutstanding'] ?? 0).toDouble(),
    outstandingInvoices: (j['outstandingInvoices'] as List? ?? [])
        .map((e) => Invoice.fromJson(e))
        .toList(),
    paidInvoices: (j['paidInvoices'] as List? ?? [])
        .map((e) => Invoice.fromJson(e))
        .toList(),
  );

  String get initials {
    final parts = residentName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return residentName.isNotEmpty ? residentName[0].toUpperCase() : '?';
  }

  String get locationLabel {
    final parts = <String>[];
    if (blockCode != null) parts.add('Block $blockCode');
    if (floor != null) parts.add('Floor $floor');
    parts.add(apartmentCode);
    return parts.join(' · ');
  }
}

// Global summary
class ManagerSummary {
  final int totalApartments;
  final int overdueCount;
  final int unpaidCount;
  final double totalOutstanding;

  ManagerSummary({
    required this.totalApartments,
    required this.overdueCount,
    required this.unpaidCount,
    required this.totalOutstanding,
  });

  factory ManagerSummary.fromJson(Map<String, dynamic> j) => ManagerSummary(
    totalApartments: j['totalApartments'] ?? 0,
    overdueCount: j['overdueCount'] ?? 0,
    unpaidCount: j['unpaidCount'] ?? 0,
    totalOutstanding: (j['totalOutstanding'] ?? 0).toDouble(),
  );
}

// Paged wrapper
class PagedManagerList {
  final List<ManagerListItem> content;
  final int totalPages;
  final int totalElements;

  PagedManagerList({
    required this.content,
    required this.totalPages,
    required this.totalElements,
  });

  factory PagedManagerList.fromJson(Map<String, dynamic> j) => PagedManagerList(
    content: (j['content'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => ManagerListItem.fromJson(e))
        .toList(),
    totalPages: j['totalPages'] ?? 1,
    totalElements: j['totalElements'] ?? 0,
  );
}
