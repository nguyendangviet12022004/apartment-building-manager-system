class BookingDetailModel {
  final int bookingId;
  
  // Resident info
  final String residentName;
  final String? residentPhone;
  final String residentEmail;
  final String unitNumber;
  
  // Service info
  final int serviceId;
  final String serviceName;
  final String? serviceDescription;
  final double? unitPrice;
  
  // Booking info
  final DateTime startTime;
  final DateTime endTime;
  final int quantity;
  final double? totalPrice;
  final String? note;
  final String status;
  
  // Timestamps
  final DateTime? createdAt;

  BookingDetailModel({
    required this.bookingId,
    required this.residentName,
    this.residentPhone,
    required this.residentEmail,
    required this.unitNumber,
    required this.serviceId,
    required this.serviceName,
    this.serviceDescription,
    this.unitPrice,
    required this.startTime,
    required this.endTime,
    required this.quantity,
    this.totalPrice,
    this.note,
    required this.status,
    this.createdAt,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      bookingId: json['bookingId'],
      residentName: json['residentName'],
      residentPhone: json['residentPhone'],
      residentEmail: json['residentEmail'],
      unitNumber: json['unitNumber'],
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      serviceDescription: json['serviceDescription'],
      unitPrice: json['unitPrice']?.toDouble(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      quantity: json['quantity'] ?? 1,
      totalPrice: json['totalPrice']?.toDouble(),
      note: json['note'],
      status: json['status'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isRejected => status == 'REJECTED';
  
  String get accountId => '#RES-${bookingId.toString().padLeft(6, '0')}';
}
