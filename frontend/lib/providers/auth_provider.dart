import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _email;
  String? _role;
  int? _apartmentId;
  bool _isApartmentVerified = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get email => _email;
  String? get role => _role;
  int? get apartmentId => _apartmentId;
  bool get isApartmentVerified => _isApartmentVerified;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    _email = prefs.getString('email');
    _role = prefs.getString('role');
    _isAuthenticated = _accessToken != null;

    // If already authenticated, initialize notifications
    if (_isAuthenticated && _email != null) {
      _notificationService.initialize().then((token) {
        if (token != null) {
          _authService.updateFcmToken(_email!, token);
        }
      });
    }

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _authService.login(email, password);
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];
      final role = response['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('email', email);
      await prefs.setString('role', role);

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _email = email;
      _role = role;
      _isAuthenticated = true;

      // Initialize notifications after successful login and send to backend
      _notificationService.initialize().then((token) {
        if (token != null) {
          _authService.updateFcmToken(email, token);
        }
      });

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? identityCard,
    String? emergencyContact,
  }) async {
    _setLoading(true);
    try {
      await _authService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        apartmentId: _apartmentId?.toString(),
        identityCard: identityCard,
        emergencyContact: emergencyContact,
      );

      // We don't log in automatically here because user wants to go to login screen
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove FCM token on backend before local logout if email is known
    if (_email != null) {
      _authService.removeFcmToken(_email!);
    }

    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('email');
    await prefs.remove('role');
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _role = null;
    _isAuthenticated = false;

    // Delete FCM token locally
    await _notificationService.deleteToken();

    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.forgotPassword(email);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> verifyCode(String email, String code) async {
    _setLoading(true);
    try {
      await _authService.verifyCode(email, code);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email, code, newPassword);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (_email == null) throw Exception('User not logged in');
    _setLoading(true);
    try {
      await _authService.changePassword(_email!, oldPassword, newPassword);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> verifyApartmentCode(String code) async {
    _setLoading(true);
    try {
      final id = await _authService.verifyApartmentCode(code);
      _apartmentId = id;
      _isApartmentVerified = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _isApartmentVerified = false;
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
