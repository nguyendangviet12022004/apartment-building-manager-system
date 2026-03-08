class ApartmentModel {
  final int id;
  final String apartmentCode;
  final int? floor;
  final double? area;
  final String? status;
  final bool used;
  final String? blockCode; // từ Block.blockCode
  final int? residentId;

  ApartmentModel({
    required this.id,
    required this.apartmentCode,
    this.floor,
    this.area,
    this.status,
    this.used = false,
    this.blockCode,
    this.residentId,
  });

  factory ApartmentModel.fromJson(Map<String, dynamic> json) => ApartmentModel(
    id: json['id'],
    apartmentCode: json['apartmentCode'] ?? '',
    floor: json['floor'],
    area: json['area'] != null ? (json['area'] as num).toDouble() : null,
    status: json['status'],
    used: json['used'] ?? false,
    blockCode: json['blockCode'],
    residentId: json['residentId'],
  );

  // "A-1205 · Block A · Floor 12"
  String get displayLabel {
    final parts = <String>[apartmentCode];
    if (blockCode != null) parts.add('Block $blockCode');
    if (floor != null) parts.add('Floor $floor');
    return parts.join(' · ');
  }

  @override
  String toString() => displayLabel;
}
