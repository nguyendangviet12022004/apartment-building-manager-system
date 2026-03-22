import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../models/booking_detail_model.dart';

class BookingService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1/bookings';

  Future<BookingListResponse> getBookings({
    String? search,
    String? status,
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
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
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
      return BookingListResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('No bookings found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal System Error, please contact administrator');
    } else {
      throw Exception('Unable to load booking list');
    }
  }

  Future<BookingDetailModel> getBookingDetails(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('$baseUrl/$bookingId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return BookingDetailModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Booking not found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal System Error, please contact administrator');
    } else {
      throw Exception('Unable to load booking details');
    }
  }
}
