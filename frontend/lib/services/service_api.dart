import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';

class ServiceApi {
  // Tự động chọn URL dựa trên nền tảng đang chạy
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1'; // Android Emulator
    }
    return 'http://localhost:8080/api/v1'; // Windows, iOS Simulator, Web
  }

  Future<List<ServiceModel>> getAmenityServices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('$baseUrl/services'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((e) => ServiceModel.fromJson(e))
          // Filter theo logic yêu cầu: chỉ lấy AMENITY
          .where((s) => s.serviceType == 'AMENITY')
          .toList();
    } else {
      throw Exception('Failed to load services: ${response.statusCode}');
    }
  }
}
