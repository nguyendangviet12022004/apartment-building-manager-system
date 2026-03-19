import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';

class ProfileService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/profile';

  Future<ProfileModel> getProfile(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('$baseUrl/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  Future<ProfileModel> updateProfile(
    int userId,
    Map<String, dynamic> updates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
