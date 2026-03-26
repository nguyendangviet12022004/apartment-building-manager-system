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

  Future<Map<String, dynamic>> createBlock({
    required String token,
    required String blockCode,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'blockCode': blockCode,
        'description': description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to create block');
    }
  }

  Future<Map<String, dynamic>> updateBlock({
    required String token,
    required int id,
    required String blockCode,
    String? description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'blockCode': blockCode,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update block');
    }
  }

  Future<void> deleteBlock({required String token, required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Check for common foreign key / dependency errors
      if (response.statusCode == 500 || response.body.contains('constraint fails')) {
        throw Exception('Cannot delete block! There are existing apartments assigned to it.');
      }
      
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
           throw Exception(errorBody['message']);
        }
        throw Exception('Failed to delete block. Please try again.');
      } catch (e) {
        if (e.toString().contains('Cannot delete this block') || e.toString().contains('Failed to delete block')) {
          rethrow;
        }
        throw Exception('Failed to delete block (Error ${response.statusCode}). Please ensure the block is not in use.');
      }
    }
  }
}
