// lib/services/reminder_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReminderResult {
  final bool pushSent;
  final bool emailSent;
  final String? pushError;
  final String? emailError;
  final String residentName;

  ReminderResult({
    required this.pushSent,
    required this.emailSent,
    this.pushError,
    this.emailError,
    required this.residentName,
  });

  factory ReminderResult.fromJson(Map<String, dynamic> j) => ReminderResult(
    pushSent: j['pushSent'] ?? false,
    emailSent: j['emailSent'] ?? false,
    pushError: j['pushError'],
    emailError: j['emailError'],
    residentName: j['residentName'] ?? '',
  );

  bool get anySuccess => pushSent || emailSent;

  String get summary {
    final parts = <String>[];
    if (pushSent) parts.add('Push ✓');
    if (emailSent) parts.add('Email ✓');
    if (pushError != null) parts.add('Push ✗');
    if (emailError != null) parts.add('Email ✗');
    return parts.join(' · ');
  }
}

class ReminderService {
  static const _base = 'http://10.0.2.2:8080/api/v1/reminders';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<int?> _getManagerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // ── Gửi reminder — BE trả 202 ngay, kết quả qua SSE ──────────────────────
  Future<void> sendReminder({
    required int apartmentId,
    required bool sendPush,
    required bool sendEmail,
    String? customMessage,
  }) async {
    final managerId = await _getManagerId();
    final res = await http.post(
      Uri.parse('$_base/send'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'apartmentId': apartmentId,
        'sendPush': sendPush,
        'sendEmail': sendEmail,
        'customMessage': customMessage,
        'managerId': managerId ?? 0,
      }),
    );
    if (res.statusCode != 202 && res.statusCode != 200) {
      throw Exception('Send reminder failed: ${res.statusCode} ${res.body}');
    }
  }

  // ── Subscribe SSE với auto-reconnect ──────────────────────────────────────
  Stream<ReminderResult> subscribeResults() {
    final controller = StreamController<ReminderResult>.broadcast();
    _connectSse(controller);
    return controller.stream;
  }

  Future<void> _connectSse(StreamController<ReminderResult> controller) async {
    const maxRetries = 5;
    const retryDelay = Duration(seconds: 3);
    int retries = 0;

    while (!controller.isClosed && retries < maxRetries) {
      try {
        final managerId = await _getManagerId();
        if (managerId == null) break;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken') ?? '';

        debugPrint(
          'SSE connecting... managerId=$managerId (attempt ${retries + 1})',
        );

        final request = http.Request(
          'GET',
          Uri.parse('$_base/events?managerId=$managerId'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';

        final client = http.Client();
        String buffer = '';

        try {
          final response = await client.send(request);

          if (response.statusCode != 200) {
            throw Exception('SSE HTTP ${response.statusCode}');
          }

          debugPrint('SSE connected');
          retries = 0; // reset retry counter khi kết nối thành công

          await for (final chunk in response.stream.transform(utf8.decoder)) {
            if (controller.isClosed) break;
            buffer += chunk;

            // Parse SSE blocks (mỗi block cách nhau bằng \n\n)
            while (buffer.contains('\n\n')) {
              final idx = buffer.indexOf('\n\n');
              final block = buffer.substring(0, idx);
              buffer = buffer.substring(idx + 2);

              String? eventName;
              String? dataLine;

              for (final line in block.split('\n')) {
                if (line.startsWith('event:')) {
                  eventName = line.substring(6).trim();
                } else if (line.startsWith('data:')) {
                  dataLine = line.substring(5).trim();
                }
              }

              // Bỏ qua heartbeat và connected events
              if (eventName == 'heartbeat' || eventName == 'connected') {
                debugPrint('SSE $eventName');
                continue;
              }

              if (eventName == 'REMINDER_RESULT' && dataLine != null) {
                try {
                  final json = jsonDecode(dataLine) as Map<String, dynamic>;
                  controller.add(ReminderResult.fromJson(json));
                } catch (e) {
                  debugPrint('SSE parse error: $e');
                }
              }
            }
          }
        } finally {
          client.close();
        }

        // Stream ended bình thường (server đóng) → reconnect
        debugPrint('SSE stream ended, reconnecting...');
      } catch (e) {
        retries++;
        debugPrint('SSE error (attempt $retries/$maxRetries): $e');
        if (retries >= maxRetries) {
          debugPrint('SSE max retries reached, giving up');
          break;
        }
      }

      if (!controller.isClosed) {
        await Future.delayed(retryDelay);
      }
    }
  }
}
