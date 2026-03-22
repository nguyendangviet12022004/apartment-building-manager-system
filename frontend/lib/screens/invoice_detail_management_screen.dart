// lib/screens/invoice_detail_management_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/manager_invoice_model.dart';
import '../models/invoice_model.dart';
import '../services/manager_invoice_service.dart';
import '../services/reminder_service.dart';

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
  bool _deleting = false;

  ManagerDetail? _detail;
  bool _loading = true;
  String? _error;

  // Reminder
  final _reminderService = ReminderService();
  StreamSubscription<ReminderResult>? _sseSub;
  bool _sending = false;
  ReminderResult? _lastResult;
  Timer? _sendingTimeout;

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
    _subscribeSse();
  }

  void _subscribeSse() {
    _sseSub = _reminderService.subscribeResults().listen(
      (result) {
        if (!mounted) return;
        _sendingTimeout?.cancel();
        setState(() {
          _lastResult = result;
          _sending = false;
        });
        _showResultSnackbar(result);
      },
      onError: (e) {
        debugPrint('SSE error: $e');
        // Reconnect tự động được xử lý trong ReminderService
      },
      onDone: () => debugPrint('SSE stream done'),
      cancelOnError: false, // Không huỷ stream khi gặp lỗi → cho phép reconnect
    );
  }

  void _showResultSnackbar(ReminderResult result) {
    final msg = result.anySuccess
        ? 'Reminder sent to ${result.residentName} · ${result.summary}'
        : 'Failed: ${result.pushError ?? result.emailError ?? 'Unknown error'}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: result.anySuccess
            ? const Color(0xFF16A34A)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          child: Stack(
            children: [
              Column(
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
              // Deleting overlay
              if (_deleting)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 14),
                        Text(
                          'Deleting invoice...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                _buildInvoiceRow(inv, canEdit: true),
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
                _buildInvoiceRow(inv, canEdit: false),
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
              onTap: _sending ? null : _sendReminder,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _sending ? _gray : _accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _sending
                      ? []
                      : [
                          BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: _sending
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
                    : const Row(
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

  Future<void> _sendReminder() async {
    if (_sending || _detail == null) return;
    final sendPush = _channels['Push Notification'] ?? false;
    final sendEmail = _channels['Email'] ?? false;
    if (!sendPush && !sendEmail) {
      _showSnack('Please select at least one channel', isError: true);
      return;
    }

    setState(() {
      _sending = true;
      _lastResult = null;
    });

    // Timeout 15s: nếu SSE không về (mất kết nối, managerId sai...)
    // tự reset _sending để UI không bị kẹt
    _sendingTimeout?.cancel();
    _sendingTimeout = Timer(const Duration(seconds: 15), () {
      if (mounted && _sending) {
        setState(() => _sending = false);
        _showSnack(
          'No response from server — check result manually',
          isError: true,
        );
      }
    });

    try {
      await _reminderService.sendReminder(
        apartmentId: _detail!.apartmentId,
        sendPush: sendPush,
        sendEmail: sendEmail,
      );
      if (!mounted) return;
      _showSnack('Reminder queued, waiting for result...');
    } catch (e) {
      _sendingTimeout?.cancel();
      if (mounted) {
        setState(() => _sending = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  // ── Invoice Row with Edit / Delete ────────────────────────────────────────
  Widget _buildInvoiceRow(Invoice inv, {required bool canEdit}) {
    final Color statusColor;
    final String statusLabel;
    switch (inv.status) {
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
                inv.invoiceCode,
                style: const TextStyle(fontSize: 11, color: _gray),
              ),
              const SizedBox(height: 2),
              Text(
                inv.monthLabel,
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
              '${_fmtVnd(inv.total.toInt())}đ',
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
        if (canEdit) ...[
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: _gray),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              if (v == 'edit') _showEditDialog(inv);
              if (v == 'delete') _confirmDelete(inv);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 16, color: _accent),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: _overdueRed,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Delete',
                      style: TextStyle(
                        color: _overdueRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Edit Invoice Dialog ────────────────────────────────────────────────────
  Future<void> _showEditDialog(Invoice inv) async {
    final dueDateCtrl = TextEditingController(
      text: inv.dueDate != null
          ? '${inv.dueDate!.day.toString().padLeft(2, '0')}/'
                '${inv.dueDate!.month.toString().padLeft(2, '0')}/'
                '${inv.dueDate!.year}'
          : '',
    );
    final lateFeeCtrl = TextEditingController(
      text: inv.lateFee.toInt().toString(),
    );
    DateTime? pickedDate = inv.dueDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Invoice',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                inv.invoiceCode,
                style: const TextStyle(
                  fontSize: 11,
                  color: _gray,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Due Date picker
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: pickedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: _accent),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) {
                    setDialogState(() {
                      pickedDate = d;
                      dueDateCtrl.text =
                          '${d.day.toString().padLeft(2, '0')}/'
                          '${d.month.toString().padLeft(2, '0')}/${d.year}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: dueDateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      labelStyle: const TextStyle(color: _gray),
                      suffixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _accent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _accent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Late Fee
              TextField(
                controller: lateFeeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Late Fee (đ)',
                  labelStyle: const TextStyle(color: _gray),
                  suffixText: 'đ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _gray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    if (pickedDate == null) return;

    final lateFee = double.tryParse(lateFeeCtrl.text) ?? 0;

    try {
      await _service.editInvoice(
        inv.id,
        dueDate: pickedDate!,
        lateFee: lateFee,
        status: inv.status.name.toUpperCase(),
        items: [], // empty = keep existing items on BE
      );
      _showSnack('Invoice updated');
      await _load();
    } catch (e) {
      _showSnack('Update failed: $e', isError: true);
    }
  }

  // ── Confirm Delete ─────────────────────────────────────────────────────────
  Future<void> _confirmDelete(Invoice inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Invoice?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice: ${inv.invoiceCode}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Amount: ${_fmtVnd(inv.total.toInt())}đ',
              style: const TextStyle(color: _gray, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _overdueRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: _overdueRed,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _overdueRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _overdueRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteInvoice(inv.id);
      _showSnack('Invoice deleted');
      await _load(); // reload — invoice sẽ biến mất khỏi list
    } catch (e) {
      _showSnack('Delete failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _overdueRed : _paidGreen,
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
