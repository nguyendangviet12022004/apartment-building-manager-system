import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'Apartment Manager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          // Check auth status here
          initialRoute: authProvider.isAuthenticated
              ? AppRoutes.home
              : AppRoutes.login,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
