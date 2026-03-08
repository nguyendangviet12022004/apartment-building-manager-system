class ServiceModel {
  final int id;
  final String serviceName;
  final String? unit;
  final double unitPrice;
  final String? description;
  final String serviceType; // METERED, FIXED, PARKING

  ServiceModel({
    required this.id,
    required this.serviceName,
    this.unit,
    required this.unitPrice,
    this.description,
    required this.serviceType,
  });

  bool get isFixed => serviceType == 'FIXED';

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'],
    serviceName: json['serviceName'] ?? '',
    unit: json['unit'],
    unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    description: json['description'],
    serviceType: json['serviceType'] ?? 'METERED',
  );
}
