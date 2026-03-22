class ResidentDetailModel {
  final int userId;
  final int residentId;
  final String fullName;
  final String firstname;
  final String lastname;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? gender;
  final String? identityCard;
  
  final String status;
  final String residentCode;
  final String ownershipType;
  
  final int? apartmentId;
  final String? building;
  final String? unit;
  final String? apartmentType;
  final double? area;
  final String? moveInDate;
  
  final String? emergencyContact;
  final String? emergencyContactRelationship;

  ResidentDetailModel({
    required this.userId,
    required this.residentId,
    required this.fullName,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.identityCard,
    required this.status,
    required this.residentCode,
    required this.ownershipType,
    this.apartmentId,
    this.building,
    this.unit,
    this.apartmentType,
    this.area,
    this.moveInDate,
    this.emergencyContact,
    this.emergencyContactRelationship,
  });

  factory ResidentDetailModel.fromJson(Map<String, dynamic> json) {
    return ResidentDetailModel(
      userId: json['userId'],
      residentId: json['residentId'],
      fullName: json['fullName'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      identityCard: json['identityCard'],
      status: json['status'],
      residentCode: json['residentCode'],
      ownershipType: json['ownershipType'],
      apartmentId: json['apartmentId'],
      building: json['building'],
      unit: json['unit'],
      apartmentType: json['apartmentType'],
      area: json['area']?.toDouble(),
      moveInDate: json['moveInDate'],
      emergencyContact: json['emergencyContact'],
      emergencyContactRelationship: json['emergencyContactRelationship'],
    );
  }

  bool get isActive => status == 'ACTIVE';
  
  String get initials {
    String first = firstname.isNotEmpty ? firstname[0] : '';
    String last = lastname.isNotEmpty ? lastname[0] : '';
    return (first + last).toUpperCase();
  }
}
