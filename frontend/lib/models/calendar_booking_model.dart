class CalendarBookingModel {
  final int bookingId;
  final String serviceName;
  final String serviceIcon;
  final String apartmentCode;
  final String residentName;
  final DateTime startTime;
  final DateTime endTime;
  final String timeSlot;
  final String status;

  CalendarBookingModel({
    required this.bookingId,
    required this.serviceName,
    required this.serviceIcon,
    required this.apartmentCode,
    required this.residentName,
    required this.startTime,
    required this.endTime,
    required this.timeSlot,
    required this.status,
  });

  factory CalendarBookingModel.fromJson(Map<String, dynamic> json) {
    return CalendarBookingModel(
      bookingId: json['bookingId'],
      serviceName: json['serviceName'],
      serviceIcon: json['serviceIcon'] ?? 'default',
      apartmentCode: json['apartmentCode'],
      residentName: json['residentName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      timeSlot: json['timeSlot'],
      status: json['status'],
    );
  }
}

class BookingCalendarResponse {
  final List<CalendarBookingModel> bookings;
  final int totalScheduled;
  final String currentDate;
  final String viewType;

  BookingCalendarResponse({
    required this.bookings,
    required this.totalScheduled,
    required this.currentDate,
    required this.viewType,
  });

  factory BookingCalendarResponse.fromJson(Map<String, dynamic> json) {
    return BookingCalendarResponse(
      bookings: (json['bookings'] as List)
          .map((item) => CalendarBookingModel.fromJson(item))
          .toList(),
      totalScheduled: json['totalScheduled'],
      currentDate: json['currentDate'],
      viewType: json['viewType'],
    );
  }
}
