import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../routes/app_routes.dart';
import '../screens/notification_detail_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return PopupMenuButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_none_outlined, size: 28),
          if (notificationProvider.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  '${notificationProvider.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      offset: const Offset(0, 50),
      onOpened: () {
        if (authProvider.accessToken != null) {
          notificationProvider.fetchNotifications(authProvider.accessToken!);
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry> items = [];

        items.add(
          const PopupMenuItem(
            enabled: false,
            child: Text(
              'Recent Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        if (notificationProvider.recentNotifications.isEmpty) {
          items.add(
            const PopupMenuItem(
              enabled: false,
              child: Text('No notifications'),
            ),
          );
        } else {
          for (var notification in notificationProvider.recentNotifications) {
            items.add(
              PopupMenuItem(
                onTap: () {
                  // Small delay to allow popup to close
                  Future.delayed(Duration.zero, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailScreen(
                          notification: notification,
                        ),
                      ),
                    );
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      notification.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        items.add(const PopupMenuDivider());
        items.add(
          PopupMenuItem(
            onTap: () {
              Future.delayed(Duration.zero, () {
                Navigator.pushNamed(context, AppRoutes.notifications);
              });
            },
            child: const Center(
              child: Text(
                'View all noti',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

        return items;
      },
    );
  }
}
