import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/request_model.dart';

class ApiRequestService {
  final String _baseUrl = 'http://10.0.2.2:8080/api/v1/requests';

  Future<RequestPageResponse> getAllAdminRequests({
    required String token,
    RequestStatus? status,
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    String url = '$_baseUrl/admin?page=$page&size=$size&sort=$sort';
    if (status != null) {
      url += '&status=${status.name}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RequestPageResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load admin requests: ${response.statusCode}');
    }
  }

  Future<RequestPageResponse> getUserRequests({
    required String token,
    required int userId,
    int page = 0,
    int size = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user/$userId?page=$page&size=$size'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RequestPageResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user requests: ${response.statusCode}');
    }
  }

  Future<RequestModel> createRequest({
    required String token,
    required int userId,
    required String title,
    required String description,
    List<File>? files,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/$userId');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;

    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath('files', file.path),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return RequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create request: ${response.statusCode}');
    }
  }

  Future<RequestModel> updateStatus({
    required String token,
    required int requestId,
    required RequestStatus status,
    String? responseText,
  }) async {
    String url = '$_baseUrl/$requestId/status?status=${status.name}';
    if (responseText != null) {
      url += '&response=$responseText';
    }

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to update request status: ${response.statusCode}',
      );
    }
  }
}
