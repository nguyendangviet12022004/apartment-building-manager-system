import 'package:flutter/material.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_drawer.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 100,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Manage the building operations from here.'),
          ],
        ),
      ),
    );
  }
}
