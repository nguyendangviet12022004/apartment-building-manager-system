import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

class BillsPage extends StatefulWidget {
  final int apartmentId;
  const BillsPage({super.key, required this.apartmentId});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  static const _bg = Color(0xFFE5E7EB);
  static const _blue = Color(0xFF2845D6);
  static const _blueLight = Color(0x1A2845D6);
  static const _grey = Color(0xFF9CA3AF);
  static const _charcoal = Color(0xFF4B5563);
  static const _orange = Color(0xFFF68048);
  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);

  final _service = InvoiceService();
  final _scrollController = ScrollController();

  InvoiceSummary? _summary;
  final List<Invoice> _invoices = [];

  int _selectedFilter = 0;
  final _filters = ['All', 'Unpaid', 'Paid', 'Overdue'];

  int _page = 0;
  bool _hasMore = true;
  bool _loadingList = false;
  bool _loadingSummary = false;
  String? _error;
  late int _apartmentId;

  InvoiceStatus? get _activeStatus => switch (_selectedFilter) {
    1 => InvoiceStatus.unpaid,
    2 => InvoiceStatus.paid,
    3 => InvoiceStatus.overdue,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _apartmentId = widget.apartmentId;
    _loadSummary();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final s = await _service.getSummary(_apartmentId);
      setState(() => _summary = s);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _page = 0;
      _hasMore = true;
      _invoices.clear();
      _error = null;
    });
    await _loadPage();
  }

  Future<void> _loadPage() async {
    if (_loadingList || !_hasMore) return;
    setState(() => _loadingList = true);
    try {
      final paged = await _service.getList(
        apartmentId: _apartmentId,
        status: _activeStatus,
        page: _page,
      );
      setState(() {
        _invoices.addAll(paged.content);
        _hasMore = _page < paged.totalPages - 1;
        _page++;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingList = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _payNow(Invoice inv) async {
    try {
      final updated = await _service.payNow(inv.id);
      setState(() {
        final idx = _invoices.indexWhere((i) => i.id == inv.id);
        if (idx != -1) _invoices[idx] = updated;
      });
      _loadSummary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                color: _blue,
                onRefresh: () async {
                  await _loadSummary();
                  await _loadFirstPage();
                },
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildFilterRow(),
                    const SizedBox(height: 16),
                    if (_error != null) _buildError(),
                    ..._invoices.map(_buildBillCard),
                    if (_loadingList)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: _blue),
                        ),
                      ),
                    if (!_loadingList && _invoices.isEmpty && _error == null)
                      _buildEmpty(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              const Text(
                'My Bills',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.tune_rounded, size: 14, color: _blue),
                SizedBox(width: 5),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 13,
                    color: _blue,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_loadingSummary && _summary == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_blue, Color(0xFF0D1A63)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    final s = _summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue, Color(0xFF0D1A63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Outstanding',
            style: TextStyle(
              color: _white.withOpacity(0.75),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s != null ? _formatVnd(s.totalOutstanding.toInt()) : '—',
            style: const TextStyle(
              color: _white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMiniStat('Unpaid', s?.unpaidCount ?? 0, _orange),
              const SizedBox(width: 12),
              _buildMiniStat(
                'Overdue',
                s?.overdueCount ?? 0,
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'Paid',
                s?.paidCount ?? 0,
                const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: const TextStyle(
              color: _white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (i) {
          final selected = _selectedFilter == i;
          return GestureDetector(
            onTap: () {
              if (_selectedFilter == i) return;
              setState(() => _selectedFilter = i);
              _loadFirstPage();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _blue : _white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  color: selected ? _white : _charcoal,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBillCard(Invoice inv) {
    final (statusColor, statusBg) = _statusStyle(inv.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 14,
                          color: _grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          inv.invoiceCode,
                          style: TextStyle(
                            color: _grey,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        inv.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  inv.monthLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: _black,
                  ),
                ),
                const SizedBox(height: 8),
                if (inv.dueLabel.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: _grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        inv.dueLabel,
                        style: TextStyle(
                          color: inv.daysUntilDue < 0
                              ? const Color(0xFFEF4444)
                              : inv.daysUntilDue <= 3
                              ? _orange
                              : _grey,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                if (inv.serviceLabels.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: _grey),
                      const SizedBox(width: 5),
                      Text(
                        inv.serviceLabels.join(' · '),
                        style: TextStyle(
                          color: _charcoal,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Due',
                          style: TextStyle(
                            color: _grey,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatVnd(inv.total.toInt()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                            color: _black,
                          ),
                        ),
                      ],
                    ),
                    inv.status == InvoiceStatus.paid
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Paid',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _payNow(inv),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _blue,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: _blue.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Pay Now',
                                    style: TextStyle(
                                      color: _white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: _white,
                                  ),
                                ],
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

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: _grey),
          const SizedBox(height: 12),
          Text(
            'No invoices found',
            style: TextStyle(color: _grey, fontSize: 15, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error ?? 'Unknown error',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _error = null);
                _loadFirstPage();
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusStyle(InvoiceStatus s) => switch (s) {
    InvoiceStatus.paid => (const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
    InvoiceStatus.overdue => (const Color(0xFFEF4444), const Color(0xFFFFE4E4)),
    _ => (_orange, const Color(0xFFFFF0E8)),
  };

  String _formatVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }
}
