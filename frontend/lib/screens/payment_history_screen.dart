// lib/screens/payment_history_screen.dart

import 'package:flutter/material.dart';
import '../models/payment_history_model.dart';
import '../services/payment_history_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int apartmentId;
  const PaymentHistoryScreen({super.key, required this.apartmentId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  // ── Resident color palette ──────────────────────────────────────────────────
  static const _bg = Color(0xFFE5E7EB);
  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2845D6);
  static const _blueLight = Color(0x1A2845D6);
  static const _blueDark = Color(0xFF0D1A63);
  static const _orange = Color(0xFFF68048);
  static const _grey = Color(0xFF9CA3AF);
  static const _charcoal = Color(0xFF4B5563);
  static const _black = Color(0xFF111827);
  static const _success = Color(0xFF16A34A);
  static const _successBg = Color(0xFFDCFCE7);
  static const _errorRed = Color(0xFFEF4444);
  static const _errorBg = Color(0xFFFFE4E4);
  static const _pendingBg = Color(0xFFFFF7ED);

  final _service = PaymentHistoryService();
  final _scrollCtrl = ScrollController();

  PagedPaymentHistory? _paged;
  final List<PaymentHistoryItem> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirst();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _page = 0;
      _hasMore = true;
    });
    try {
      final p = await _service.getHistory(
        apartmentId: widget.apartmentId,
        page: 0,
      );
      setState(() {
        _paged = p;
        _items.addAll(p.content);
        _hasMore = 0 < p.totalPages - 1;
        _page = 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final p = await _service.getHistory(
        apartmentId: widget.apartmentId,
        page: _page,
      );
      setState(() {
        _items.addAll(p.content);
        _hasMore = _page < p.totalPages - 1;
        _page++;
      });
    } catch (_) {
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
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
                  : RefreshIndicator(
                      color: _blue,
                      onRefresh: _loadFirst,
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          if (_paged != null) _buildSummaryCard(),
                          const SizedBox(height: 16),
                          if (_items.isEmpty) _buildEmpty(),
                          ..._items.map(_buildTransactionCard),
                          if (_loadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _blue,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: _blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _black,
                  fontFamily: 'Inter',
                ),
              ),
              if (_paged != null)
                Text(
                  '${_paged!.totalElements} transactions',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _grey,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary Card ─────────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final s = _paged!.summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue, _blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: _white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Total Paid',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtVnd(s.totalPaid),
            style: const TextStyle(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(
                '${s.successCount}',
                'Successful',
                _success,
                _successBg,
              ),
              const SizedBox(width: 10),
              _buildStat('${s.failedCount}', 'Failed', _errorRed, _errorBg),
              const SizedBox(width: 10),
              _buildStat(
                '${s.totalTransactions}',
                'Total',
                _white,
                _white.withOpacity(0.15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label, Color valColor, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: valColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: valColor == _white ? _white.withOpacity(0.8) : valColor,
                fontSize: 10,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction Card ─────────────────────────────────────────────────────────
  Widget _buildTransactionCard(PaymentHistoryItem item) {
    final (statusColor, statusBg, statusIcon) = _statusStyle(item.status);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status stripe
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.invoiceMonth.isNotEmpty
                                    ? item.invoiceMonth
                                    : item.invoiceCode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _black,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Text(
                              _fmtVnd(item.amount),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: item.status == PaymentStatus.success
                                    ? _success
                                    : _black,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 11,
                              color: _grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.invoiceCode,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _grey,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.status.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: _grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.createdAt != null
                                  ? _fmtDateTime(item.createdAt!)
                                  : '—',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _grey,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (item.bankCode != null &&
                                item.bankCode!.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Icon(
                                Icons.account_balance_rounded,
                                size: 11,
                                color: _grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.bankCode!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _grey,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction Detail Bottom Sheet ──────────────────────────────────────────
  void _showDetail(PaymentHistoryItem item) {
    final (statusColor, statusBg, _) = _statusStyle(item.status);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    item.status.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 1.2,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmtVnd(item.amount),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Details
            _detailRow('Invoice', item.invoiceCode),
            _detailRow('Period', item.invoiceMonth),
            _detailRow('Transaction Ref', item.txnRef),
            if (item.vnpayTransactionNo != null &&
                item.vnpayTransactionNo!.isNotEmpty)
              _detailRow('VNPay Txn No', item.vnpayTransactionNo!),
            if (item.bankCode != null && item.bankCode!.isNotEmpty)
              _detailRow('Bank', item.bankCode!),
            if (item.vnpayResponseCode != null)
              _detailRow('Response Code', item.vnpayResponseCode!),
            _detailRow(
              'Initiated',
              item.createdAt != null ? _fmtDateTime(item.createdAt!) : '—',
            ),
            if (item.paidAt != null)
              _detailRow('Paid At', _fmtDateTime(item.paidAt!)),
            const SizedBox(height: 8),
            // Close
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _blueLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: _blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _grey,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _black,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    ),
  );

  // ── Error / Empty ─────────────────────────────────────────────────────────
  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: _grey),
        const SizedBox(height: 12),
        Text(_error ?? 'Error', style: const TextStyle(color: _grey)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _loadFirst,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: _white,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 56,
          color: _grey.withOpacity(0.5),
        ),
        const SizedBox(height: 14),
        const Text(
          'No payment history yet',
          style: TextStyle(color: _grey, fontSize: 15, fontFamily: 'Inter'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Completed payments will appear here',
          style: TextStyle(color: _grey, fontSize: 12, fontFamily: 'Inter'),
        ),
      ],
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  (Color, Color, IconData) _statusStyle(PaymentStatus s) => switch (s) {
    PaymentStatus.success => (_success, _successBg, Icons.check_circle_rounded),
    PaymentStatus.failed => (_errorRed, _errorBg, Icons.cancel_rounded),
    PaymentStatus.cancelled => (_orange, _pendingBg, Icons.cancel_outlined),
    PaymentStatus.pending => (_orange, _pendingBg, Icons.schedule_rounded),
  };

  String _fmtVnd(double amount) {
    final s = amount.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  String _fmtDateTime(DateTime d) {
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year} '
        '${pad(d.hour)}:${pad(d.minute)}';
  }
}
