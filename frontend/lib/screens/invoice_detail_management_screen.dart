// lib/screens/invoice_detail_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/manager_invoice_model.dart';
import '../models/invoice_model.dart';
import '../services/manager_invoice_service.dart';

class InvoiceDetailManagementScreen extends StatefulWidget {
  final int apartmentId;
  const InvoiceDetailManagementScreen({super.key, required this.apartmentId});

  @override
  State<InvoiceDetailManagementScreen> createState() =>
      _InvoiceDetailManagementScreenState();
}

class _InvoiceDetailManagementScreenState
    extends State<InvoiceDetailManagementScreen> {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const _accent = Color(0xFF88304E);
  static const _accentLight = Color(0x1A88304E);
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);
  static const _bg = Color(0xFFF5F5F5);
  static const _gray = Color(0xFF9CA3AF);
  static const _slate = Color(0xFF4B5563);
  static const _lightGray = Color(0xFFE5E7EB);
  static const _overdueRed = Color(0xFFEF4444);
  static const _unpaidAmber = Color(0xFFF59E0B);
  static const _paidGreen = Color(0xFF16A34A);

  final _service = ManagerInvoiceService();

  ManagerDetail? _detail;
  bool _loading = true;
  String? _error;

  // Reminder toggles
  final Map<String, bool> _channels = {
    'Push Notification': true,
    'Email': true,
    'SMS': false,
  };

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
      final d = await _service.getDetail(widget.apartmentId);
      setState(() => _detail = d);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _accent),
                      )
                    : _error != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        color: _accent,
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildResidentCard(),
                              const SizedBox(height: 12),
                              _buildContractPeriod(),
                              const SizedBox(height: 12),
                              if (_detail!.outstandingInvoices.isNotEmpty)
                                _buildOutstandingSection(),
                              if (_detail!.outstandingInvoices.isNotEmpty)
                                const SizedBox(height: 12),
                              if (_detail!.paidInvoices.isNotEmpty)
                                _buildPaidSection(),
                              if (_detail!.paidInvoices.isNotEmpty)
                                const SizedBox(height: 12),
                              _buildSendReminderSection(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
            color: _black,
          ),
          const Text(
            'Invoice Detail',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _black,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Management',
              style: TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resident Card ──────────────────────────────────────────────────────────
  Widget _buildResidentCard() {
    final d = _detail!;
    return _AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Text(
                d.initials,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RESIDENT',
                  style: TextStyle(
                    color: _gray,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.residentName.isNotEmpty ? d.residentName : '—',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.locationLabel,
                  style: const TextStyle(
                    color: _slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 11, color: _gray),
                    const SizedBox(width: 4),
                    Text(
                      _maskEmail(d.residentEmail),
                      style: const TextStyle(color: _gray, fontSize: 11),
                    ),
                    if (d.residentPhone != null &&
                        d.residentPhone!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.phone_outlined, size: 11, color: _gray),
                      const SizedBox(width: 4),
                      Text(
                        d.residentPhone!,
                        style: const TextStyle(color: _gray, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contract Period ────────────────────────────────────────────────────────
  Widget _buildContractPeriod() {
    final d = _detail!;
    final hasContract = d.contractStart != null && d.contractEnd != null;

    return _AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: _accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contract Period',
                style: TextStyle(
                  color: _gray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasContract
                    ? '${d.contractStart} – ${d.contractEnd}'
                    : 'Not available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasContract ? _black : _gray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Outstanding Section ────────────────────────────────────────────────────
  Widget _buildOutstandingSection() {
    final invoices = _detail!.outstandingInvoices;
    final total = _detail!.totalOutstanding;

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(color: _overdueRed, title: 'Outstanding Invoices'),
          const SizedBox(height: 14),
          ...List.generate(invoices.length, (i) {
            final inv = invoices[i];
            final isLast = i == invoices.length - 1;
            return Column(
              children: [
                _InvoiceRowItem(invoice: inv),
                if (!isLast)
                  const Divider(height: 20, color: Color(0xFFE5E7EB)),
              ],
            );
          }),
          Divider(height: 20, thickness: 1.5, color: _lightGray),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Due',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _black,
                ),
              ),
              Text(
                '${_fmtVnd(total.toInt())}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _overdueRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Paid Section ───────────────────────────────────────────────────────────
  Widget _buildPaidSection() {
    final invoices = _detail!.paidInvoices;

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(color: _paidGreen, title: 'Paid'),
          const SizedBox(height: 14),
          ...List.generate(invoices.length, (i) {
            final inv = invoices[i];
            final isLast = i == invoices.length - 1;
            return Column(
              children: [
                _InvoiceRowItem(invoice: inv),
                if (!isLast)
                  const Divider(height: 16, color: Color(0xFFE5E7EB)),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Send Reminder ──────────────────────────────────────────────────────────
  Widget _buildSendReminderSection() {
    final d = _detail!;
    final outCount = d.outstandingInvoices.length;
    final totalStr = '${_fmtVnd(d.totalOutstanding.toInt())}đ';

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.send_rounded, color: _accent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Send via',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Channel toggles
          ..._channels.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReminderToggle(
                icon: switch (e.key) {
                  'Push Notification' => Icons.notifications_rounded,
                  'Email' => Icons.email_rounded,
                  _ => Icons.sms_rounded,
                },
                label: e.key,
                value: e.value,
                onChanged: (v) => setState(() => _channels[e.key] = v),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Message preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Message Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _slate,
                      ),
                    ),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: _slate,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: '"Dear '),
                      TextSpan(
                        text: d.residentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _black,
                        ),
                      ),
                      TextSpan(
                        text: ', you have outstanding invoices totaling ',
                      ),
                      TextSpan(
                        text:
                            '$totalStr ($outCount invoice${outCount != 1 ? 's' : ''})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _black,
                        ),
                      ),
                      const TextSpan(text: '. Please pay to avoid late fees."'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Send button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _sendReminder,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: _white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Send Reminder Now',
                      style: TextStyle(
                        color: _white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendReminder() {
    final channels = _channels.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder sent to ${_detail?.residentName ?? ''} via $channels',
        ),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: _gray),
        const SizedBox(height: 12),
        Text(
          _error ?? 'Error',
          textAlign: TextAlign.center,
          style: TextStyle(color: _gray),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _accent,
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _maskEmail(String email) {
    if (email.isEmpty) return '—';
    final at = email.indexOf('@');
    if (at <= 2) return email;
    return '${email.substring(0, 3)}***${email.substring(at)}';
  }

  String _fmtVnd(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
  final Widget child;
  const _AppCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final Color color;
  final String title;
  const _SectionHeader({required this.color, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _InvoiceRowItem extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceRowItem({required this.invoice});

  static const _overdueRed = Color(0xFFEF4444);
  static const _unpaidAmber = Color(0xFFF59E0B);
  static const _paidGreen = Color(0xFF16A34A);
  static const _gray = Color(0xFF9CA3AF);
  static const _black = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    switch (invoice.status) {
      case InvoiceStatus.overdue:
        statusColor = _overdueRed;
        statusLabel = 'Overdue';
        break;
      case InvoiceStatus.paid:
        statusColor = _paidGreen;
        statusLabel = 'Paid';
        break;
      default:
        statusColor = _unpaidAmber;
        statusLabel = 'Unpaid';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.invoiceCode,
                style: const TextStyle(fontSize: 11, color: _gray),
              ),
              const SizedBox(height: 2),
              Text(
                invoice.monthLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _black,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_fmt(invoice.total.toInt())}đ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ReminderToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ReminderToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _accent = Color(0xFF88304E);
  static const _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: value ? _accent.withOpacity(0.1) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: value ? _accent : _gray),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value ? const Color(0xFF111827) : _gray,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _accent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
