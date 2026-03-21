import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/request_model.dart';

class ApiRequestService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/requests';

  Future<RequestPageResponse> getAllAdminRequests({
    required String token,
    RequestStatus? status,
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    String url = '$baseUrl/admin?page=$page&size=$size&sort=$sort';
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
      Uri.parse('$baseUrl/user/$userId?page=$page&size=$size'),
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

  Future<List<RequestModel>> getMyRequests({
    required String token,
    String? status,
    String? issueType,
    String? sort,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status != 'All Status') queryParams['status'] = status.toUpperCase();
    if (issueType != null && issueType != 'Issue Type') queryParams['issueType'] = issueType;
    if (sort != null && sort != 'Sort By') {
      if (sort == 'Newest') {
        queryParams['sort'] = 'newest';
      } else if (sort == 'Oldest') {
        queryParams['sort'] = 'oldest';
      } else if (sort == 'Priority') {
        queryParams['sort'] = 'priority';
      }
    }
    queryParams['page'] = page.toString();
    queryParams['size'] = size.toString();

    final uri = Uri.parse('$baseUrl/my').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded['content'] != null) {
        final List<dynamic> list = decoded['content'];
        return list.map((e) => RequestModel.fromJson(e)).toList();
      }
      return <RequestModel>[];
    } else {
      throw Exception('Failed to load user requests');
    }
  }

  Future<RequestModel> createRequest({
    required String token,
    required int userId,
    required String title,
    required String description,
    List<File>? files,
  }) async {
    final uri = Uri.parse('$baseUrl/user/$userId');
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

  Future<RequestModel> submitResidentRequest({
    required String token,
    required String title,
    required String description,
    required String issueType,
    required String priority,
    String? location,
    String? occurrenceTime,
    List<File>? files,
  }) async {
    final uri = Uri.parse(baseUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['issueType'] = issueType;
    request.fields['priority'] = priority;
    if (location != null) request.fields['location'] = location;
    if (occurrenceTime != null) request.fields['occurrenceTime'] = occurrenceTime;

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
      throw Exception('Failed to submit request: ${response.statusCode}');
    }
  }

  Future<RequestModel> updateStatus({
    required String token,
    required int requestId,
    required RequestStatus status,
    String? responseText,
  }) async {
    String url = '$baseUrl/$requestId/status?status=${status.name}';
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

  Future<RequestModel> updateTimeline({
    required String token,
    required int requestId,
    required DateTime solvedBy,
  }) async {
    // Backend expects LocalDateTime in a format it can parse. ISO-8601 is usually fine.
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/$requestId/timeline?solvedBy=${solvedBy.toIso8601String()}',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update timeline: ${response.statusCode}');
    }
  }
}
