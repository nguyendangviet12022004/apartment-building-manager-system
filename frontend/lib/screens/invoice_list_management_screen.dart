// lib/screens/invoice_list_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/manager_invoice_model.dart';
import '../services/manager_invoice_service.dart';
import '../routes/app_routes.dart';
import 'invoice_detail_management_screen.dart';

class InvoiceListManagementScreen extends StatefulWidget {
  const InvoiceListManagementScreen({super.key});

  @override
  State<InvoiceListManagementScreen> createState() =>
      _InvoiceListManagementScreenState();
}

class _InvoiceListManagementScreenState
    extends State<InvoiceListManagementScreen> {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const _accent = Color(0xFF88304E);
  static const _accentLight = Color(0x1A88304E);
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);
  static const _bg = Color(0xFFF5F5F5);
  static const _gray = Color(0xFF9CA3AF);
  static const _slate = Color(0xFF4B5563);
  static const _overdueRed = Color(0xFFEF4444);
  static const _unpaidAmber = Color(0xFFF59E0B);
  static const _paidGreen = Color(0xFF16A34A);
  static const _warningBg = Color(0xFFFFF7ED);
  static const _warningBorder = Color(0xFFFBD38D);
  static const _warningText = Color(0xFF92400E);

  final _service = ManagerInvoiceService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  ManagerSummary? _summary;
  final List<ManagerListItem> _items = [];
  String _filter = 'All';
  final _filters = ['All', 'Has Debt', 'Overdue', 'Unpaid'];

  int _page = 0;
  bool _hasMore = true;
  bool _loadingList = false;
  bool _loadingSummary = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadFirst();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChange);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChange() {
    // Debounce simple: reload on every change (có thể thêm debounce nếu cần)
    _loadFirst();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final s = await _service.getSummary();
      setState(() => _summary = s);
    } catch (e) {
      debugPrint('Summary error: $e');
    } finally {
      setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _page = 0;
      _hasMore = true;
      _items.clear();
      _error = null;
    });
    await _loadPage();
  }

  Future<void> _loadMore() async => _loadPage();

  Future<void> _loadPage() async {
    if (_loadingList || !_hasMore) return;
    setState(() => _loadingList = true);
    try {
      final filterParam = switch (_filter) {
        'Has Debt' => 'hasDebt',
        'Overdue' => 'overdue',
        'Unpaid' => 'unpaid',
        _ => null,
      };
      final paged = await _service.getList(
        status: filterParam,
        search: _searchCtrl.text.trim(),
        page: _page,
      );
      setState(() {
        _items.addAll(paged.content);
        _hasMore = _page < paged.totalPages - 1;
        _page++;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingList = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final overdueCount = _summary?.overdueCount ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: () async {
                    await _loadSummary();
                    await _loadFirst();
                  },
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    slivers: [
                      SliverToBoxAdapter(child: _buildSearch()),
                      SliverToBoxAdapter(child: _buildFilters()),
                      if (overdueCount > 0)
                        SliverToBoxAdapter(
                          child: _buildWarningBanner(overdueCount),
                        ),
                      if (_error != null)
                        SliverToBoxAdapter(child: _buildError()),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildCard(_items[i]),
                          childCount: _items.length,
                        ),
                      ),
                      if (_loadingList)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(color: _accent),
                            ),
                          ),
                        ),
                      if (!_loadingList && _items.isEmpty && _error == null)
                        SliverToBoxAdapter(child: _buildEmpty()),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
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

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.createInvoice),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF88304E), Color(0xFF522546)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: _white, size: 20),
              SizedBox(width: 8),
              Text(
                'Create new invoice',
                style: TextStyle(
                  color: _white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
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
            onPressed: () => Navigator.maybePop(context),
            color: _black,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _black,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 12,
                    color: _gray,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Summary chips
          if (_summary != null) ...[
            _SummaryChip('${_summary!.overdueCount}', 'Overdue', _overdueRed),
            const SizedBox(width: 6),
            _SummaryChip('${_summary!.unpaidCount}', 'Unpaid', _unpaidAmber),
            const SizedBox(width: 8),
          ],
          _BulkReminderButton(accent: _accent, accentLight: _accentLight),
        ],
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: _gray, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 15, color: _black),
                decoration: const InputDecoration(
                  hintText: 'Search apartment...',
                  hintStyle: TextStyle(color: _gray, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16, color: _gray),
                onPressed: () {
                  _searchCtrl.clear();
                  _loadFirst();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Filters ────────────────────────────────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final sel = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (_filter == f) return;
                  setState(() => _filter = f);
                  _loadFirst();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? _accent : _white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: _accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: sel ? _white : _slate,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Warning banner ──────────────────────────────────────────────────────────
  Widget _buildWarningBanner(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _warningBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _warningBorder),
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count apartments have outstanding debt',
                style: const TextStyle(
                  color: _warningText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Invoice Card ────────────────────────────────────────────────────────────
  Widget _buildCard(ManagerListItem inv) {
    final Color statusBg;
    final String statusLabel;
    final String subtitleText;
    final Color subtitleColor;

    switch (inv.status) {
      case 'overdue':
        statusBg = _overdueRed;
        statusLabel = 'Overdue';
        subtitleText =
            '${inv.monthsOverdue} month${inv.monthsOverdue != 1 ? 's' : ''} overdue';
        subtitleColor = _overdueRed;
        break;
      case 'paid':
        statusBg = _paidGreen;
        statusLabel = 'Paid';
        subtitleText = 'All paid ✓';
        subtitleColor = _paidGreen;
        break;
      default:
        statusBg = _unpaidAmber;
        statusLabel = 'Unpaid';
        subtitleText =
            '${inv.unpaidCount} invoice${inv.unpaidCount != 1 ? 's' : ''} pending';
        subtitleColor = _unpaidAmber;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: () async {
          final refreshed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  InvoiceDetailManagementScreen(apartmentId: inv.apartmentId),
            ),
          );
          if (refreshed == true) {
            await _loadSummary();
            await _loadFirst();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar initials
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accent, _accent.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    inv.initials,
                    style: const TextStyle(
                      color: _white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APARTMENT',
                      style: TextStyle(
                        color: _gray,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inv.apartmentCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (inv.aptLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        inv.aptLabel,
                        style: const TextStyle(
                          color: _gray,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Amount + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    inv.totalDebt == 0
                        ? '0đ'
                        : '${_fmtVnd(inv.totalDebt.toInt())}đ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _black,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                      statusLabel,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 56, color: _gray),
        const SizedBox(height: 12),
        Text('No invoices found', style: TextStyle(color: _gray, fontSize: 15)),
      ],
    ),
  );

  Widget _buildError() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _overdueRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Error',
              style: const TextStyle(color: _overdueRed, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _error = null);
              _loadFirst();
            },
            child: const Text(
              'Retry',
              style: TextStyle(
                color: _overdueRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

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

// ── Helper widgets ────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String count, label;
  final Color color;
  const _SummaryChip(this.count, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkReminderButton extends StatelessWidget {
  final Color accent, accentLight;
  const _BulkReminderButton({required this.accent, required this.accentLight});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bulk reminder sent'),
          backgroundColor: accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: accent, size: 16),
            const SizedBox(width: 6),
            Text(
              'Bulk Reminder',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
