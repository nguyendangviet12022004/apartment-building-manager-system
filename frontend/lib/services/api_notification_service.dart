import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class ApiNotificationService {
  final String _baseUrl =
      'http://10.0.2.2:8080/api/v1/test-notifications'; // Using test controller as requested paths

  Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user'),
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
      Uri.parse('$_baseUrl/mark-all-read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all as read: ${response.statusCode}');
    }
  }
}
