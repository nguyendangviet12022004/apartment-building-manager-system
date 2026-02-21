import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiNotificationService _apiService = ApiNotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get recentNotifications =>
      _notifications.take(10).toList();
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _apiService.getNotifications(token);
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String token) async {
    try {
      await _apiService.markAllAsRead(token);
      // Optimistically update local state
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          content: n.content,
          detail: n.detail,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}
