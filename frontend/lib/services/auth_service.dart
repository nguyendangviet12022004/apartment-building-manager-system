import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Or your machine's IP address for physical devices
  // static const String baseUrl = 'http://10.0.2.2:8080/api/v1/auth';
  static const String baseUrl = 'http://localhost:8080/api/v1/auth';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? apartmentId,
    String? identityCard,
    String? emergencyContact,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
        'apartmentId': apartmentId,
        'identityCard': identityCard,
        'emergencyContact': emergencyContact,
      }),
    );

    return _handleResponse(response);
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/forgot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    _handleResponse(response);
  }

  Future<void> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    _handleResponse(response);
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );
    _handleResponse(response);
  }

  Future<void> changePassword(
    String email,
    String oldPassword,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/change'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    _handleResponse(response);
  }

  Future<int> verifyApartmentCode(String code) async {
    final response = await http.post(
      Uri.parse(
        'http://localhost:8080/api/v1/apartment-codes/verify?code=$code',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    final result = _handleResponse(response);
    if (result.containsKey('id')) {
      return result['id'] as int;
    }
    if (result.containsKey('message')) {
      return int.parse(result['message']);
    }
    throw Exception('Failed to get apartment ID from response');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    dynamic decodedBody;

    if (response.body.isNotEmpty) {
      if (contentType.contains('application/json')) {
        try {
          decodedBody = jsonDecode(response.body);
        } catch (e) {
          decodedBody = response.body;
        }
      } else {
        decodedBody = response.body;
      }
    } else {
      decodedBody = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      } else if (decodedBody is int) {
        return {'id': decodedBody};
      } else {
        return {'message': decodedBody.toString()};
      }
    } else {
      String message = 'An error occurred';
      if (decodedBody is Map && decodedBody.containsKey('message')) {
        message = decodedBody['message'];
      } else if (response.body.isNotEmpty) {
        message = response.body;
      }
      throw Exception(message);
    }
  }
}
