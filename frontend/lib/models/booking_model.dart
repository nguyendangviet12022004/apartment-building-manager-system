class BookingModel {
  final int id;
  final int serviceId;
  final String serviceName;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // PENDING, CONFIRMED, REJECTED, CANCELLED
  final int quantity;
  final String? note;

  BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.quantity,
    this.note,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Backend trả về object 'service' lồng bên trong
    final serviceObj = json['service'] ?? {};

    return BookingModel(
      id: json['id'],
      serviceId: serviceObj['id'] ?? 0,
      serviceName: serviceObj['serviceName'] ?? 'Unknown Service',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? 'PENDING',
      quantity: json['quantity'] ?? 1,
      note: json['note'],
    );
  }
}
