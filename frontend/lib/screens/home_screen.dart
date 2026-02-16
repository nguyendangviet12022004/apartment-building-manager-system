import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartment Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 100, color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Welcome Home!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('You are successfully logged in.'),
          ],
        ),
      ),
    );
  }
}
