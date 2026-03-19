import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_model.dart';

class BlockService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/blocks';

  Future<List<BlockModel>> getAllBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BlockModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load blocks');
    }
  }
}
