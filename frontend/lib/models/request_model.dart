enum RequestStatus { PENDING, IN_PROGRESS, RESOLVED, REJECTED }

class RequestModel {
  final int id;
  final String title;
  final String description;
  final RequestStatus status;
  final DateTime createdAt;
  final String? response;
  final DateTime? responseAt;
  final int userId;
  final String userEmail;
  final String userFullName;

  RequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.response,
    this.responseAt,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: RequestStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      response: json['response'],
      responseAt: json['responseAt'] != null
          ? DateTime.parse(json['responseAt'])
          : null,
      userId: json['userId'],
      userEmail: json['userEmail'],
      userFullName: json['userFullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'response': response,
      'responseAt': responseAt?.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'userFullName': userFullName,
    };
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
