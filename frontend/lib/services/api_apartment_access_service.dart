import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiApartmentAccessService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/apartment-codes';

  Future<String> generateCode({
    required String token,
    required int apartmentId,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$apartmentId/generate').replace(queryParameters: {'email': email}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return response.body; 
    } else {
      String errorMessage = 'Failed to generate access code';
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (_) {}
      throw errorMessage;
    }
  }

  Future<int> verifyCode({
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify').replace(queryParameters: {'code': code}),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return int.parse(response.body); // backend returns apartmentId
    } else {
      String errorMessage = 'Invalid or expired code';
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (_) {}
      throw errorMessage;
    }
  }
}
