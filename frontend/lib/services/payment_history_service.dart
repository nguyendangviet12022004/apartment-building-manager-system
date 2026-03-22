// lib/services/payment_history_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_history_model.dart';

class PaymentHistoryService {
  static const _base = 'http://10.0.2.2:8080/api/v1/payment-history';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PagedPaymentHistory> getHistory({
    required int apartmentId,
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'apartmentId': '$apartmentId',
        'page': '$page',
        'size': '$size',
      },
    );
    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('Failed to load history: ${res.statusCode}');
    }
    return PagedPaymentHistory.fromJson(jsonDecode(res.body));
  }
}
