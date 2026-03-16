// lib/screens/vnpay_webview_screen.dart
//
// pubspec.yaml:
//   webview_flutter: ^4.10.0
//   url_launcher: ^6.3.0

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';

class VNPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String txnRef;

  const VNPayWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.txnRef,
  });

  @override
  State<VNPayWebViewScreen> createState() => _VNPayWebViewScreenState();
}

class _VNPayWebViewScreenState extends State<VNPayWebViewScreen> {
  static const _primary = Color(0xFF2845D6);
  static const _success = Color(0xFF16A34A);

  final _paymentService = PaymentService();
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _isVerifying = false;
  // null = chưa xong, true = thành công, false = thất bại/huỷ
  bool? _paymentResult;

  // Deep link scheme — khớp với VNPayConfig.RETURN_URL = "myapp://vnpay-return"
  static const _returnScheme = 'myapp';

  static const _externalSchemes = [
    'intent',
    'vnpay',
    'momo',
    'zalopay',
    'viettelpay',
    'bidv',
    'vcb',
    'acb',
    'tpb',
    'mbbank',
    'vib',
    'ocb',
    'hdbank',
    'scb',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (e) {
            if (e.url?.startsWith('intent') == true) return;
            debugPrint('WebView error: ${e.description}');
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _handleNavigation(NavigationRequest req) {
    final url = req.url;
    debugPrint('>>> nav: $url');

    final uri = Uri.tryParse(url);
    final scheme = uri?.scheme ?? '';

    // 1. Deep link return từ VNPay → "myapp://vnpay-return?vnp_ResponseCode=00&..."
    if (scheme == _returnScheme) {
      _handleDeepLinkReturn(uri!);
      return NavigationDecision.prevent;
    }

    // 2. Intent URL (Android deep link app ngân hàng)
    if (url.startsWith('intent://')) {
      _launchIntentUrl(url);
      return NavigationDecision.prevent;
    }

    // 3. Custom scheme app ngân hàng
    if (_externalSchemes.contains(scheme)) {
      _launchExternalUrl(url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  // ── Deep link return: parse params → gửi BE verify → pop result ──────────
  Future<void> _handleDeepLinkReturn(Uri uri) async {
    if (_paymentResult != null) return; // guard double-call

    debugPrint('>>> deep link return: $uri');

    final params = Map<String, String>.from(uri.queryParameters);
    final responseCode = params['vnp_ResponseCode'];

    // Nếu user cancel tại VNPay (responseCode != 00) → pop false ngay
    if (responseCode != '00') {
      _finishWith(false);
      return;
    }

    // Thanh toán thành công → gửi lên BE verify chữ ký + update status
    setState(() => _isVerifying = true);
    try {
      final success = await _paymentService.verifyPayment(params);
      _finishWith(success);
    } catch (e) {
      debugPrint('Verify error: $e');
      _finishWith(false);
    }
  }

  void _finishWith(bool success) {
    if (_paymentResult != null) return;
    _paymentResult = success;
    if (mounted) Navigator.of(context).pop(success);
  }

  // ── Intent URL ────────────────────────────────────────────────────────────
  Future<void> _launchIntentUrl(String intentUrl) async {
    try {
      final uri = Uri.parse(intentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      final fallback = _extractFallbackUrl(intentUrl);
      if (fallback != null) {
        final fbUri = Uri.parse(fallback);
        if (await canLaunchUrl(fbUri)) {
          await launchUrl(fbUri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      final package = _extractPackage(intentUrl);
      if (package != null) {
        await launchUrl(
          Uri.parse('https://play.google.com/store/apps/details?id=$package'),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      _showSnack('Banking app not installed');
    } catch (e) {
      _showSnack('Cannot open banking app');
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('External URL error: $e');
    }
  }

  String? _extractFallbackUrl(String intentUrl) {
    final m = RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(intentUrl);
    if (m == null) return null;
    return Uri.decodeComponent(m.group(1) ?? '');
  }

  String? _extractPackage(String intentUrl) =>
      RegExp(r'package=([^;]+)').firstMatch(intentUrl)?.group(1);

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  Future<void> _confirmCancel() async {
    // Chỉ hỏi nếu chưa có kết quả
    if (_paymentResult != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Payment?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Your payment has not been completed. Are you sure you want to go back?',
          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Continue Paying',
              style: TextStyle(color: Color(0xFF2845D6), fontFamily: 'Inter'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFEF4444), fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) _finishWith(false);
    // confirmed == false → user chọn Continue, không làm gì cả
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && !_isVerifying)
            const Center(child: CircularProgressIndicator(color: _primary)),
          if (_isVerifying)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verifying payment...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 18,
            color: Color(0xFF374151),
          ),
        ),
        onPressed: _confirmCancel,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'VNPAY',
            style: TextStyle(
              color: Color(0xFF005BAA),
              fontWeight: FontWeight.w800,
              fontSize: 18,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, size: 10, color: _success),
                SizedBox(width: 4),
                Text(
                  'Secure',
                  style: TextStyle(
                    fontSize: 10,
                    color: _success,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE5E7EB), height: 1),
      ),
    );
  }
}
