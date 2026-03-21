class ServiceModel {
  final int id;
  final String serviceName;
  final String? unit;
  final double unitPrice;
  final String? description;
  final String serviceType;
  final bool metered;
  final bool active;
  final int capacity;
  final String? openingTime;
  final String? closingTime;

  ServiceModel({
    required this.id,
    required this.serviceName,
    this.unit,
    required this.unitPrice,
    this.description,
    required this.serviceType,
    required this.metered,
    required this.active,
    required this.capacity,
    this.openingTime,
    this.closingTime,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serviceName: json['serviceName'],
      unit: json['unit'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      description: json['description'],
      serviceType: json['serviceType'],
      metered: json['metered'] ?? false,
      active: json['active'] ?? true,
      capacity: json['capacity'] ?? 1,
      openingTime: json['openingTime'],
      closingTime: json['closingTime'],
    );
  }

  bool get isFixed {
    return serviceType == 'FIXED';
  }
}
