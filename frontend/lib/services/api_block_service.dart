import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiBlockService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/blocks';

  Future<List<Map<String, dynamic>>> getBlocks({required String token}) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load blocks');
    }
  }
}
