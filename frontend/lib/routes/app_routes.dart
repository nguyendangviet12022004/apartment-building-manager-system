import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
  };
}
