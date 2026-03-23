class BookingModel {
  final int bookingId;
  final String residentName;
  final String unitNumber;
  final String serviceName;
  final String serviceIcon;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final double? totalPrice;
  final int quantity;

  BookingModel({
    required this.bookingId,
    required this.residentName,
    required this.unitNumber,
    required this.serviceName,
    required this.serviceIcon,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.totalPrice,
    required this.quantity,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'],
      residentName: json['residentName'],
      unitNumber: json['unitNumber'],
      serviceName: json['serviceName'],
      serviceIcon: json['serviceIcon'] ?? 'default',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
      totalPrice: json['totalPrice']?.toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'CONFIRMED';
  bool get isRejected => status == 'REJECTED';
}

class BookingListResponse {
  final List<BookingModel> bookings;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  BookingListResponse({
    required this.bookings,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    return BookingListResponse(
      bookings: (json['bookings'] as List)
          .map((item) => BookingModel.fromJson(item))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}
