// lib/screens/invoice_detail_screen.dart
//
// Nhận vào Invoice object (từ bills_page) hoặc invoiceId để fetch riêng.
// Pay Now dùng cùng flow VNPay như bills_page.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';
import '../services/payment_service.dart';
import '../screens/vnpay_webview_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  // Truyền id để fetch, hoặc invoice sẵn (sẽ fetch lại để có items)
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFE5E7EB);
  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2845D6);
  static const _blueLight = Color(0x1A2845D6);
  static const _gray = Color(0xFF9CA3AF);
  static const _slate = Color(0xFF4B5563);
  static const _orange = Color(0xFFF68048);
  static const _navy = Color(0xFF111827);
  static const _inputBg = Color(0xFFF3F4F6);
  static const _border = Color(0xFFCED4DA);
  static const _offWhite = Color(0xFFF5F5F5);
  static const _success = Color(0xFF16A34A);

  final _invoiceService = InvoiceService();
  final _paymentService = PaymentService();

  Invoice? _invoice;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inv = await _invoiceService.getById(widget.invoiceId);
      setState(() => _invoice = inv);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Pay Now ───────────────────────────────────────────────────────────────
  Future<void> _payNow() async {
    final inv = _invoice;
    if (inv == null || _paying) return;

    setState(() => _paying = true);
    try {
      final result = await _paymentService.createPaymentUrl(inv.id);
      if (!mounted) return;

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VNPayWebViewScreen(
            paymentUrl: result['paymentUrl']!,
            txnRef: result['txnRef']!,
          ),
        ),
      );

      if (!mounted) return;

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment successful! 🎉'),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        await _load(); // reload để cập nhật status PAID
      } else if (success == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment cancelled or failed'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _blue))
                  : _error != null
                  ? _buildError()
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _navy,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Invoice Detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _navy,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 22, color: _navy),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    final inv = _invoice!;
    final isPaid = inv.status == InvoiceStatus.paid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          _buildHeaderCard(inv),
          const SizedBox(height: 10),
          _buildApartmentCard(inv),
          const SizedBox(height: 10),
          _buildChargesCard(inv),
          const SizedBox(height: 14),
          if (!isPaid) _buildPayButton(inv),
          if (!isPaid) const SizedBox(height: 10),
          _buildActionRow(),
        ],
      ),
    );
  }

  // ── Header Card ───────────────────────────────────────────────────────────
  Widget _buildHeaderCard(Invoice inv) {
    final isPaid = inv.status == InvoiceStatus.paid;
    final isOverdue = inv.status == InvoiceStatus.overdue;
    final statusColor = isPaid
        ? _blue
        : isOverdue
        ? const Color(0xFFEF4444)
        : _orange;
    final statusBg = isPaid
        ? _blueLight
        : isOverdue
        ? const Color(0xFFFFE4E4)
        : _orange.withOpacity(0.12);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    inv.invoiceCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _gray,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _StatusBadge(
                label: inv.status.label,
                color: statusColor,
                bg: statusBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inv.monthLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _DateChip(
                icon: Icons.calendar_today_rounded,
                label: inv.invoiceDate != null
                    ? 'Issued: ${_fmtShort(inv.invoiceDate!)}'
                    : '',
                color: _gray,
              ),
              const SizedBox(width: 10),
              if (inv.dueDate != null)
                _DateChip(
                  icon: Icons.timer_outlined,
                  label: 'Due: ${_fmtShort(inv.dueDate!)}',
                  color: _orange,
                  bold: true,
                ),
            ],
          ),
          // Warning/info banner
          const SizedBox(height: 10),
          if (!isPaid) _buildDueBanner(inv),
          if (isPaid) _buildPaidBanner(),
        ],
      ),
    );
  }

  Widget _buildDueBanner(Invoice inv) {
    final d = inv.daysUntilDue;
    final isOverdue = d < 0;
    final color = isOverdue ? const Color(0xFFEF4444) : _orange;
    final msg = isOverdue
        ? '${-d} days overdue — Late fee may apply'
        : d == 0
        ? 'Due today — Pay now to avoid late fee'
        : 'Due in $d days — Pay early to avoid late fee';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.access_time_rounded, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _success.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: _success,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Payment received — Thank you!',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Apartment Card ────────────────────────────────────────────────────────
  Widget _buildApartmentCard(Invoice inv) {
    final block = inv.blockCode != null ? 'Block ${inv.blockCode}' : null;
    final floor = inv.apartmentFloor != null
        ? 'Floor ${inv.apartmentFloor}'
        : null;
    final detail = [
      block,
      floor,
      inv.apartmentCode,
    ].whereType<String>().join(' — ');

    return _Card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment_rounded, size: 20, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APARTMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _gray,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.isNotEmpty ? detail : inv.apartmentCode ?? '—',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (inv.apartmentArea != null)
                      _Tag('${inv.apartmentArea!.toStringAsFixed(0)} m²'),
                    if (inv.residentName != null) ...[
                      const SizedBox(width: 6),
                      _Tag(inv.residentName!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _gray, size: 18),
        ],
      ),
    );
  }

  // ── Charges Card ──────────────────────────────────────────────────────────
  Widget _buildChargesCard(Invoice inv) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CHARGES BREAKDOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _gray,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${inv.items.length} items',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Line items
          if (inv.items.isEmpty)
            // Fallback: show serviceLabels nếu items chưa có
            ...inv.serviceLabels.map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _blueLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.receipt_outlined,
                        size: 16,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(inv.items.length, (i) {
              final item = inv.items[i];
              final isLast = i == inv.items.length - 1;
              return Column(
                children: [
                  _ChargeRow(item: item),
                  if (!isLast)
                    const Divider(color: _offWhite, height: 1, thickness: 0.5),
                ],
              );
            }),

          // Totals
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  'Subtotal',
                  _fmtVnd(inv.subtotal.toInt()),
                  color: _slate,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  'Late Fee',
                  _fmtVnd(inv.lateFee.toInt()),
                  color: inv.lateFee > 0 ? const Color(0xFFEF4444) : _gray,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: _border, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Due',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _fmtVnd(inv.total.toInt()),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pay Button ────────────────────────────────────────────────────────────
  Widget _buildPayButton(Invoice inv) {
    return GestureDetector(
      onTap: _paying ? null : _payNow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _paying ? [_gray, _gray] : [const Color(0xFF3151F5), _blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _paying
              ? []
              : [
                  BoxShadow(
                    color: _blue.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: _paying
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: _white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pay ${_fmtVnd(inv.total.toInt())} Now',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Action Row ────────────────────────────────────────────────────────────
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _OutlineButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Download PDF',
            iconColor: _slate,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OutlineButton(
            icon: Icons.flag_outlined,
            label: 'Report Issue',
            iconColor: _orange,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: _gray),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _gray, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: _white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmtShort(DateTime d) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month]} ${d.day}';
  }

  String _fmtVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCED4DA), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool bold;
  const _DateChip({
    required this.icon,
    required this.label,
    required this.color,
    this.bold = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  final InvoiceItem item;
  const _ChargeRow({required this.item});

  IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('electric') || n.contains('điện'))
      return Icons.bolt_outlined;
    if (n.contains('water') || n.contains('nước'))
      return Icons.water_drop_outlined;
    if (n.contains('park') || n.contains('xe'))
      return Icons.directions_car_outlined;
    if (n.contains('manage') || n.contains('quản lý'))
      return Icons.shield_outlined;
    if (n.contains('internet') || n.contains('wifi')) return Icons.wifi_rounded;
    return Icons.receipt_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final detail = item.quantity > 0 && item.unit != null
        ? '${_fmt(item.quantity)} ${item.unit} × ${_fmtVnd(item.unitPrice.toInt())}'
        : _fmtVnd(item.unitPrice.toInt());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x1A2845D6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _icon(item.serviceName),
              size: 16,
              color: const Color(0xFF2845D6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.serviceName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmtVnd(item.amount.toInt()),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  String _fmtVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData? icon;
  const _SummaryRow(this.label, this.value, {required this.color, this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCED4DA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
