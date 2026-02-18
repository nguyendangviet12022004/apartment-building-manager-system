import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
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

      _accessToken = accessToken;
      _refreshToken = refreshToken;
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

      _accessToken = accessToken;
      _refreshToken = refreshToken;
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
    _accessToken = null;
    _refreshToken = null;
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
