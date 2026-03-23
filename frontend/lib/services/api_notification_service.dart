import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class ApiNotificationService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/notifications';

  Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map((dynamic item) => NotificationModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  Future<void> markAllAsRead(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mark-all-read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all as read: ${response.statusCode}');
    }
  }

  Future<void> sendNotification({
    required String token,
    required String title,
    required String content,
    String? detail,
    int? userId,
    bool toAll = false,
  }) async {
    final queryParams = {
      'title': title,
      'content': content,
      'toAll': toAll.toString(),
    };
    if (detail != null) queryParams['detail'] = detail;
    if (userId != null) queryParams['userId'] = userId.toString();

    final response = await http.post(
      Uri.parse('$baseUrl/send').replace(queryParameters: queryParams),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }
}
