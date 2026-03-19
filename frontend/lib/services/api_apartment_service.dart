import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiApartmentService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/apartments';

  Future<void> createApartment({
    required String token,
    required String apartmentCode,
    required int floor,
    required double area,
    required String status,
    required int blockId,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'apartmentCode': apartmentCode,
        'floor': floor,
        'area': area,
        'status': status,
        'blockId': blockId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Failed to create apartment';
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        if (errorData.containsKey('errors')) {
           final Map<String, dynamic> errors = errorData['errors'];
           errorMessage = errors.values.first.toString();
        } else if (errorData.containsKey('message')) {
           errorMessage = errorData['message'];
        } else {
           errorMessage = response.body; 
        }
      } catch (_) {
        errorMessage = response.body;
      }
      // Remove 'Exception: ' prefix when throwing by just throwing a formatted string or exception 
      throw errorMessage;
    }
  }
}
