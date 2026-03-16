// lib/services/invoice_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  static const _base = 'http://10.0.2.2:8080/api/v1/invoices';

  // Lấy token từ SharedPreferences và build headers
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Summary ──────────────────────────────────────────
  Future<Invoice> getById(int id) async {
    final res = await http.get(
      Uri.parse('$_base/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to load invoice: ${res.statusCode}');
    return Invoice.fromJson(jsonDecode(res.body));
  }

  Future<InvoiceSummary> getSummary(int apartmentId) async {
    final uri = Uri.parse(
      '$_base/summary',
    ).replace(queryParameters: {'apartmentId': apartmentId.toString()});
    final res = await http.get(uri, headers: await _authHeaders());
    _check(res);
    return InvoiceSummary.fromJson(jsonDecode(res.body));
  }

  // ── List (paginated, optional status filter) ─────────
  Future<PagedInvoice> getList({
    required int apartmentId,
    InvoiceStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'apartmentId': apartmentId.toString(),
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null) {
      params['status'] = status.name.toUpperCase();
    }

    final uri = Uri.parse(_base).replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    _check(res);
    return PagedInvoice.fromJson(jsonDecode(res.body));
  }

  // ── Pay Now ──────────────────────────────────────────
  Future<Invoice> payNow(int invoiceId) async {
    final uri = Uri.parse('$_base/$invoiceId/status');
    final res = await http.patch(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'status': 'PAID'}),
    );
    _check(res);
    return Invoice.fromJson(jsonDecode(res.body));
  }

  // ── Error helper ─────────────────────────────────────
  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
