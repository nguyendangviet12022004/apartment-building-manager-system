import 'dart:convert';

class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String? detail;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    this.detail,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      detail: json['detail'],
      data: _parseData(json['data']),
      isRead: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static Map<String, dynamic>? _parseData(dynamic data) {
    if (data == null) return null;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
