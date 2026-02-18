import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get email => _email;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    _email = prefs.getString('email');
    _isAuthenticated = _accessToken != null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _authService.login(email, password);
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('email', email);

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _email = email;
      _isAuthenticated = true;
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
  }) async {
    _setLoading(true);
    try {
      final response = await _authService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
      );

      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('email', email);

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _email = email;
      _isAuthenticated = true;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('email');
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _isAuthenticated = false;
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
