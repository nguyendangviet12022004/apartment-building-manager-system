import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';

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
    final userId = prefs.getInt(
      'userId',
    ); // Giả định userId được lưu khi đăng nhập

    final response = await http.get(
      Uri.parse('$baseUrl/services'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (userId != null) 'X-User-ID': '$userId',
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

  Future<List<dynamic>> getMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/my'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (userId != null) 'X-User-ID': '$userId',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body; // Trả về List<dynamic> để khớp với màn hình history
    } else {
      throw Exception('Failed to load my bookings: ${response.body}');
    }
  }

  // Lấy lịch đã đặt của một service trong ngày cụ thể
  Future<List<dynamic>> getBookingSchedule(int serviceId, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/schedule?serviceId=$serviceId&date=$date'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (userId != null) 'X-User-ID': '$userId',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load schedule: ${response.statusCode}');
    }
  }

  // Gửi yêu cầu đặt chỗ mới
  Future<void> createBooking(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (userId != null) 'X-User-ID': '$userId',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');

    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (userId != null) 'X-User-ID': '$userId',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }
}
