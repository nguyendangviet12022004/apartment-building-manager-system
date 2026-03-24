enum RequestStatus { PENDING, APPROVED, REJECTED }

enum MediaType { IMAGE, VIDEO }

class RequestMediaModel {
  final String url;
  final MediaType type;

  RequestMediaModel({required this.url, required this.type});

  factory RequestMediaModel.fromJson(Map<String, dynamic> json) {
    return RequestMediaModel(
      url: json['url'],
      type: MediaType.values.byName(json['type']),
    );
  }
}

class RequestModel {
  final int id;
  final String title;
  final String description;
  final RequestStatus status;
  final String? issueType;
  final String? priority;
  final DateTime createdAt;
  final DateTime? solvedBy;
  final String? response;
  final DateTime? responseAt;
  final String? adminName;
  final int userId;
  final String userEmail;
  final String userFullName;
  final String? userApartmentCode;
  final List<RequestMediaModel> media;

  RequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.issueType,
    this.priority,
    required this.createdAt,
    this.solvedBy,
    this.response,
    this.responseAt,
    this.adminName,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    this.userApartmentCode,
    required this.media,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: RequestStatus.values.byName(json['status'] ?? 'PENDING'),
      issueType: json['issueType'],
      priority: json['priority'] ?? 'LOW',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      solvedBy: json['solvedBy'] != null
          ? DateTime.parse(json['solvedBy'])
          : null,
      response: json['response'],
      responseAt: json['responseAt'] != null
          ? DateTime.parse(json['responseAt'])
          : null,
      adminName: json['adminName'],
      userId: json['userId'],
      userEmail: json['userEmail'],
      userFullName: json['userFullName'],
      userApartmentCode: json['userApartmentCode'],
      media:
          (json['media'] as List<dynamic>?)
              ?.map((m) => RequestMediaModel.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class RequestPageResponse {
  final List<RequestModel> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final int size;

  RequestPageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
  });

  factory RequestPageResponse.fromJson(Map<String, dynamic> json) {
    return RequestPageResponse(
      content: (json['content'] as List)
          .map((i) => RequestModel.fromJson(i))
          .toList(),
      totalPages: json['totalPages'],
      totalElements: json['totalElements'],
      number: json['number'],
      size: json['size'],
    );
  }
}
