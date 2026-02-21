import 'package:flutter/material.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_drawer.dart';

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Home'),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 100, color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Welcome, Resident!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Manage your apartment services here.'),
          ],
        ),
      ),
    );
  }
}
