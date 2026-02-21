import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/resident_home_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/apartment_verify_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String residentHome = '/resident-home';
  static const String adminHome = '/admin-home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  static const String verifyApartment = '/verify-apartment';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    residentHome: (context) => const ResidentHomeScreen(),
    adminHome: (context) => const AdminHomeScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    changePassword: (context) => const ChangePasswordScreen(),
    verifyApartment: (context) => const ApartmentVerifyScreen(),
    notifications: (context) => const NotificationsScreen(),
  };
}
