class ResidentModel {
  final int userId;
  final int residentId;
  final String fullName;
  final String? firstname;
  final String? lastname;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String initials;
  
  // Apartment info
  final int? apartmentId;
  final String? apartmentCode;
  final String? blockCode;
  final String? unitNumber;
  
  // Status
  final String status;           // ACTIVE, INACTIVE
  final String ownershipType;    // OWNER, TENANT
  
  // Additional info
  final String? identityCard;
  final String? emergencyContact;
  final String? moveInDate;

  ResidentModel({
    required this.userId,
    required this.residentId,
    required this.fullName,
    this.firstname,
    this.lastname,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.initials,
    this.apartmentId,
    this.apartmentCode,
    this.blockCode,
    this.unitNumber,
    required this.status,
    required this.ownershipType,
    this.identityCard,
    this.emergencyContact,
    this.moveInDate,
  });

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      userId: json['userId'] as int,
      residentId: json['residentId'] as int,
      fullName: json['fullName'] as String,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      initials: json['initials'] as String,
      apartmentId: json['apartmentId'] as int?,
      apartmentCode: json['apartmentCode'] as String?,
      blockCode: json['blockCode'] as String?,
      unitNumber: json['unitNumber'] as String?,
      status: json['status'] as String? ?? 'INACTIVE',
      ownershipType: json['ownershipType'] as String? ?? 'OWNER',
      identityCard: json['identityCard'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      moveInDate: json['moveInDate'] as String?,
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isOwner => ownershipType == 'OWNER';
  bool get isTenant => ownershipType == 'TENANT';
}

class ResidentListResponse {
  final List<ResidentModel> residents;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  ResidentListResponse({
    required this.residents,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ResidentListResponse.fromJson(Map<String, dynamic> json) {
    return ResidentListResponse(
      residents: (json['residents'] as List<dynamic>)
          .map((item) => ResidentModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
