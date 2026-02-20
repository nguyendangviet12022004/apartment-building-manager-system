import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            onSelected: (value) async {
              if (value == 'change_password') {
                Navigator.pushNamed(context, AppRoutes.changePassword);
              } else if (value == 'logout') {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
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
