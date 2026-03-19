// lib/models/profile_model.dart

class VehicleInfo {
  final int id;
  final String type;         // "Car" / "Motorcycle"
  final String licensePlate;
  final String? cardNumber;
  final String status;       // "ACTIVE" / "INACTIVE"

  VehicleInfo({
    required this.id,
    required this.type,
    required this.licensePlate,
    this.cardNumber,
    required this.status,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> j) => VehicleInfo(
        id:           j['id'],
        type:         j['type'] ?? 'Car',
        licensePlate: j['licensePlate'] ?? '',
        cardNumber:   j['cardNumber'],
        status:       j['status'] ?? 'ACTIVE',
      );
}

class CompletionItem {
  final String label;
  final bool completed;
  final int weight;

  const CompletionItem({
    required this.label,
    required this.completed,
    required this.weight,
  });

  factory CompletionItem.fromJson(Map<String, dynamic> j) => CompletionItem(
        label:     j['label'] ?? '',
        completed: j['completed'] ?? false,
        weight:    j['weight'] ?? 0,
      );
}

class ProfileModel {
  // Identity
  final int userId;
  final String accountId;
  final String firstname;
  final String lastname;
  final String fullName;
  final String? avatarUrl;
  final String initials;

  // Contact (masked by default – BR-03)
  final String? emailMasked;
  final String? phoneMasked;
  final String? emailFull;
  final String? phoneFull;
  final bool emailVerified;
  final bool phoneVerified;

  // Personal
  final String? dateOfBirth;
  final String? gender;

  // Apartment
  final int? apartmentId;
  final String? apartmentCode;
  final String? apartmentCodeFull;
  final String? blockCode;
  final int? floor;
  final String? unit;
  final double? area;
  final String? apartmentType;
  final String? ownershipStatus;
  final String? moveInDate;
  final String? apartmentStatus;

  // Resident
  final String? identityCard;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

// Preferences
final bool? emailNotifications;
final bool? pushNotifications;

  // Vehicles
  final List<VehicleInfo> vehicles;

  // Security
  final String? lastLogin;
  final bool twoFactorEnabled;

  // Preferences
  final String language;
  final String notificationPref;
  final String theme;

  // Completion (BR-01)
  final int profileCompletion;
  final List<CompletionItem> completionItems;

  const ProfileModel({
    required this.userId,
    required this.accountId,
    required this.firstname,
    required this.lastname,
    required this.fullName,
    this.avatarUrl,
    required this.initials,
    this.emailMasked,
    this.phoneMasked,
    this.emailFull,
    this.phoneFull,
    required this.emailVerified,
    required this.phoneVerified,
    this.dateOfBirth,
    this.gender,
    this.apartmentId,
    this.apartmentCode,
    this.apartmentCodeFull,
    this.blockCode,
    this.floor,
    this.unit,
    this.area,
    this.apartmentType,
    this.ownershipStatus,
    this.moveInDate,
    this.apartmentStatus,
    this.identityCard,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.vehicles,
    this.lastLogin,
    required this.twoFactorEnabled,
    required this.language,
    required this.notificationPref,
    required this.theme,
    required this.profileCompletion,
    required this.completionItems,
    this.emergencyContactRelationship,
    this.emailNotifications,
    this.pushNotifications,
  });

  /// "Tower A • 17th Floor"
  String get buildingLabel {
    final parts = <String>[];
    if (blockCode != null) parts.add('Tower $blockCode');
    if (floor != null) parts.add('${_ordinal(floor!)} Floor');
    return parts.join(' • ');
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        userId:                j['userId'],
        accountId:             j['accountId'] ?? '',
        firstname:             j['firstname'] ?? '',
        lastname:              j['lastname'] ?? '',
        fullName:              j['fullName'] ?? '',
        avatarUrl:             j['avatarUrl'],
        initials:              j['initials'] ?? '',
        emailMasked:           j['emailMasked'],
        phoneMasked:           j['phoneMasked'],
        emailFull:             j['emailFull'],
        phoneFull:             j['phoneFull'],
        emailVerified:         j['emailVerified'] ?? false,
        phoneVerified:         j['phoneVerified'] ?? false,
        dateOfBirth:           j['dateOfBirth'],
        gender:                j['gender'],
        apartmentId:           j['apartmentId'],
        apartmentCode:         j['apartmentCode'],
        apartmentCodeFull:     j['apartmentCodeFull'],
        blockCode:             j['blockCode'],
        floor:                 j['floor'],
        unit:                  j['unit'],
        area:                  j['area'] != null ? (j['area'] as num).toDouble() : null,
        apartmentType:         j['apartmentType'],
        ownershipStatus:       j['ownershipStatus'],
        moveInDate:            j['moveInDate'],
        apartmentStatus:       j['apartmentStatus'],
        identityCard:          j['identityCard'],
        emergencyContactName:  j['emergencyContactName'],
        emergencyContactPhone: j['emergencyContactPhone'],
        vehicles: (j['vehicles'] as List? ?? [])
            .map((e) => VehicleInfo.fromJson(e))
            .toList(),
        emergencyContactRelationship: j['emergencyContactRelationship'],
        emailNotifications: j['emailNotifications'],
        pushNotifications: j['pushNotifications'],
        lastLogin:         j['lastLogin'],
        twoFactorEnabled:  j['twoFactorEnabled'] ?? false,
        language:          j['language'] ?? 'English',
        notificationPref:  j['notificationPref'] ?? 'Push, Email',
        theme:             j['theme'] ?? 'Light',
        profileCompletion: j['profileCompletion'] ?? 0,
        completionItems: (j['completionItems'] as List? ?? [])
            .map((e) => CompletionItem.fromJson(e))
            .toList(),
      );
}