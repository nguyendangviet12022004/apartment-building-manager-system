import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/resident_model.dart';
import '../models/resident_detail_model.dart';

class ResidentService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/residents';

  Future<ResidentListResponse> getResidents({
    String? search,
    String? building,
    String? status,
    String? type,
    int page = 0,
    int pageSize = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (building != null && building.isNotEmpty) {
      queryParams['building'] = building;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ResidentListResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('No residents found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal System Error, please contact administrator');
    } else {
      throw Exception('Unable to load resident list');
    }
  }

  Future<ResidentDetailModel> getResidentDetails(int residentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('$baseUrl/$residentId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ResidentDetailModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Resident not found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal System Error, please contact administrator');
    } else {
      throw Exception('Unable to load resident details');
    }
  }
}
