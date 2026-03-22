// lib/services/manager_invoice_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manager_invoice_model.dart';

class ManagerInvoiceService {
  static const _base = 'http://10.0.2.2:8080/api/v1/invoices';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET /manager/summary
  Future<ManagerSummary> getSummary() async {
    final res = await http.get(
      Uri.parse('$_base/manager/summary'),
      headers: await _authHeaders(),
    );
    _check(res);
    return ManagerSummary.fromJson(jsonDecode(res.body));
  }

  // GET /manager?status=overdue&search=A501&page=0&size=20
  Future<PagedManagerList> getList({
    String? status, // null | "overdue" | "unpaid" | "paid" | "hasDebt"
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'size': '$size'};
    if (status != null && status != 'All') params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$_base/manager').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    _check(res);
    return PagedManagerList.fromJson(jsonDecode(res.body));
  }

  // GET /manager/apartment/{apartmentId}
  Future<ManagerDetail> getDetail(int apartmentId) async {
    final res = await http.get(
      Uri.parse('$_base/manager/apartment/$apartmentId'),
      headers: await _authHeaders(),
    );
    _check(res);
    return ManagerDetail.fromJson(jsonDecode(res.body));
  }

  // PUT /api/v1/invoices/{id} — edit invoice
  Future<void> editInvoice(
    int invoiceId, {
    required DateTime dueDate,
    required double lateFee,
    required String status,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await http.put(
      Uri.parse('$_base/$invoiceId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'dueDate': dueDate.toIso8601String(),
        'lateFee': lateFee,
        'status': status,
        'items': items,
      }),
    );
    _check(res);
  }

  // DELETE /api/v1/invoices/{id}
  Future<void> deleteInvoice(int invoiceId) async {
    final res = await http.delete(
      Uri.parse('$_base/$invoiceId'),
      headers: await _authHeaders(),
    );
    _check(res);
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }
}
