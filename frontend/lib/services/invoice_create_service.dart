import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import '../models/invoice_model.dart';
import '../models/apartment_model.dart';

class InvoiceCreateService {
  // static const _baseInvoice = 'http://10.0.2.2:8080/api/v1/invoices';
  // static const _baseService = 'http://10.0.2.2:8080/api/v1/services';
  // static const _baseApartment = 'http://10.0.2.2:8080/api/v1/apartments';

  static const _baseInvoice = 'http://localhost:8080/api/v1/invoices';
  static const _baseService = 'http://localhost:8080/api/v1/services';
  static const _baseApartment = 'http://localhost:8080/api/v1/apartments';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Apartments ────────────────────────────────────────
  Future<List<ApartmentModel>> getApartments() async {
    final res = await http.get(
      Uri.parse(_baseApartment),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load apartments: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => ApartmentModel.fromJson(e)).toList();
  }

  // ── Services ──────────────────────────────────────────
  Future<List<ServiceModel>> getServices() async {
    final res = await http.get(
      Uri.parse(_baseService),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load services: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => ServiceModel.fromJson(e)).toList();
  }

  // ── Create Invoice ────────────────────────────────────
  Future<Invoice> createInvoice({
    required int apartmentId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<Map<String, dynamic>> items,
    double lateFee = 0,
  }) async {
    final body = jsonEncode({
      'apartmentId': apartmentId,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'lateFee': lateFee,
      'status': 'UNPAID',
      'items': items,
    });
    final res = await http.post(
      Uri.parse(_baseInvoice),
      headers: await _authHeaders(),
      body: body,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Create invoice failed ${res.statusCode}: ${res.body}');
    }
    return Invoice.fromJson(jsonDecode(res.body));
  }
}
