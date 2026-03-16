import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_auth_service.dart';
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
  int? _userId;
  int? _apartmentId;
  bool _isApartmentVerified = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get email => _email;
  String? get role => _role;
  int? get userId => _userId;
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
    _userId = prefs.getInt('userId');
    _apartmentId = prefs.getInt('apartmentId');
    _isAuthenticated = _accessToken != null;

    // Nếu đã login nhưng chưa có apartmentId → gọi API lấy lại
    if (_isAuthenticated && _apartmentId == null && _accessToken != null) {
      await _fetchAndSaveApartmentId(_accessToken!);
    }

    if (_isAuthenticated && _email != null) {
      _notificationService.initialize().then((token) {
        if (token != null) _authService.updateFcmToken(_email!, token);
      });
    }

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _authService.login(email, password);
      debugPrint('LOGIN RESPONSE: $response');

      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final role = response['role'] as String;
      final userId = response['userId'] as int;

      // Decode JWT để lấy apartment_id (backend encode trong token)
      int? apartmentId = response['apartmentId'] as int?;
      apartmentId ??= _decodeApartmentIdFromJwt(accessToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('email', email);
      await prefs.setString('role', role);
      await prefs.setInt('userId', userId);

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _email = email;
      _role = role;
      _userId = userId;
      _isAuthenticated = true;

      // Nếu login response không có apartmentId → gọi API riêng
      if (apartmentId == null) {
        apartmentId = await _fetchAndSaveApartmentId(accessToken);
      } else {
        await prefs.setInt('apartmentId', apartmentId);
        _apartmentId = apartmentId;
      }

      _notificationService.initialize().then((token) {
        if (token != null) _authService.updateFcmToken(email, token);
      });

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Gọi GET /api/v1/users/me/apartment, lưu vào prefs & state
  Future<int?> _fetchAndSaveApartmentId(String accessToken) async {
    try {
      if (userId == null) return null;
      final id = await _authService.fetchApartmentId(userId!);
      if (id != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('apartmentId', id);
        _apartmentId = id;
        notifyListeners();
      }
      return id;
    } catch (e) {
      debugPrint('fetchApartmentId error: $e');
      return null;
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
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    if (_email != null) _authService.removeFcmToken(_email!);

    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('email');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('apartmentId');

    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _role = null;
    _userId = null;
    _apartmentId = null;
    _isAuthenticated = false;

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('apartmentId', id);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _isApartmentVerified = false;
      _setLoading(false);
      rethrow;
    }
  }

  /// Decode JWT payload (không verify signature) để lấy apartment_id
  int? _decodeApartmentIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // Base64url → Base64 chuẩn
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      // Padding
      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      // JWT encode là apartment_id (snake_case)
      return map['apartment_id'] as int?;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
