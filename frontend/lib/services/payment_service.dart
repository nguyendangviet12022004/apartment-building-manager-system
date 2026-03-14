// lib/services/payment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const _base = 'http://10.0.2.2:8080/api/v1/payment';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Gọi BE để lấy payment URL
  Future<Map<String, String>> createPaymentUrl(int invoiceId) async {
    final res = await http.post(
      Uri.parse('$_base/create?invoiceId=$invoiceId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create payment URL: ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'paymentUrl': json['paymentUrl'] as String,
      'txnRef': json['txnRef'] as String,
      'invoiceId': json['invoiceId'] as String,
    };
  }

  // Gửi params từ deep link lên BE verify + update status
  Future<bool> verifyPayment(Map<String, String> params) async {
    final res = await http.post(
      Uri.parse('$_base/verify'),
      headers: await _authHeaders(),
      body: jsonEncode(params),
    );
    if (res.statusCode != 200) return false;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['code'] == '00';
  }
}
