// lib/screens/create_invoice_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/service_model.dart';
import '../models/apartment_model.dart';
import '../services/invoice_create_service.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage>
    with SingleTickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────
  static const _primary = Color(0xFF88304E);
  static const _dark = Color(0xFF522546);
  static const _darkDeep = Color(0xFF2D1B2E);
  static const _accent = Color(0xFF4B5563);
  static const _sand = Color(0xFFF5F5F5);
  static const _white = Color(0xFFFFFFFF);
  static const _grey = Color(0xFF9CA3AF);
  static const _greyLight = Color(0xFFE5E7EB);
  static const _success = Color(0xFF16A34A);

  final _api = InvoiceCreateService();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Data ─────────────────────────────────────────────
  List<ApartmentModel> _apartments = [];
  List<ServiceModel> _allServices = [];
  ApartmentModel? _selectedApartment;
  bool _loadingInit = true;
  bool _submitting = false;
  String? _error;

  // ── Form state ────────────────────────────────────────
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _dueDays = 15;
  final List<_ServiceLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadInit();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final l in _lines) l.ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadInit() async {
    try {
      final results = await Future.wait([
        _api.getApartments(),
        _api.getServices(),
      ]);
      setState(() {
        _apartments = results[0] as List<ApartmentModel>;
        _allServices = results[1] as List<ServiceModel>;
        _loadingInit = false;
      });
      _animCtrl.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingInit = false;
      });
    }
  }

  // ── Computed ─────────────────────────────────────────
  double get _subtotal => _lines.fold(0, (sum, l) {
    final qty = double.tryParse(l.ctrl.text) ?? 0;
    return sum +
        (l.service.isFixed ? l.service.unitPrice : qty * l.service.unitPrice);
  });

  DateTime get _invoiceDate =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _dueDate => _invoiceDate.add(Duration(days: _dueDays));

  // ── Actions ──────────────────────────────────────────
  void _addService(ServiceModel svc) {
    if (_lines.any((l) => l.service.id == svc.id)) return;
    setState(() => _lines.add(_ServiceLine(service: svc)));
  }

  void _removeLine(int idx) {
    _lines[idx].ctrl.dispose();
    setState(() => _lines.removeAt(idx));
  }

  Future<void> _submit() async {
    if (_selectedApartment == null) {
      _showSnack('Please select an apartment', isError: true);
      return;
    }
    if (_lines.isEmpty) {
      _showSnack('Add at least one service', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final items = _lines.map((l) {
        final qty = double.tryParse(l.ctrl.text) ?? 0;
        return {
          'serviceId': l.service.id,
          'quantity': l.service.isFixed ? 1 : qty,
        };
      }).toList();

      await _api.createInvoice(
        apartmentId: _selectedApartment!.id,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        items: items,
      );

      if (mounted) {
        _showSnack('Invoice created successfully!');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sand,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loadingInit
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _error != null
                ? _buildErrorState()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      children: [
                        _buildApartmentPicker(),
                        const SizedBox(height: 14),
                        _buildMonthPicker(),
                        const SizedBox(height: 14),
                        _buildDueDaySelector(),
                        const SizedBox(height: 20),
                        _buildServicesSection(),
                        if (_lines.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildSubtotalCard(),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (_lines.isEmpty || _selectedApartment == null)
          ? null
          : _buildSubmitFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _dark, _darkDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: _white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Invoice',
                    style: TextStyle(
                      color: _white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Select apartment & services',
                    style: TextStyle(
                      color: _white.withOpacity(0.65),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 13,
                      color: _white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Manager',
                      style: TextStyle(
                        color: _white.withOpacity(0.9),
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Apartment Picker ──────────────────────────────────
  Widget _buildApartmentPicker() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.apartment_rounded, 'Select Apartment'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _sand,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedApartment != null
                    ? _primary.withOpacity(0.4)
                    : _greyLight,
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ApartmentModel>(
                value: _selectedApartment,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                hint: Text(
                  'Choose apartment...',
                  style: TextStyle(color: _grey, fontFamily: 'Inter'),
                ),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                items: _apartments.map((apt) {
                  return DropdownMenuItem(
                    value: apt,
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: _primary,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt.apartmentCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (apt.floor != null)
                              Text(
                                'Floor ${apt.floor}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _grey,
                                  fontFamily: 'Inter',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() {
                  _selectedApartment = val;
                  _lines.clear(); // reset services when apartment changes
                }),
              ),
            ),
          ),
          if (_selectedApartment != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: _primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedApartment!.apartmentCode} selected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _primary,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Month Picker ──────────────────────────────────────
  Widget _buildMonthPicker() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.calendar_month_rounded, 'Billing Month'),
          const SizedBox(height: 12),
          Row(
            children: [
              _navBtn(
                Icons.chevron_left_rounded,
                () => setState(
                  () => _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _monthName(_selectedMonth.month),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _darkDeep,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        '${_selectedMonth.year}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _grey,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _navBtn(
                Icons.chevron_right_rounded,
                () => setState(
                  () => _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoBadge(
            'Invoice date: 1 ${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
          ),
        ],
      ),
    );
  }

  // ── Due Day Selector ──────────────────────────────────
  Widget _buildDueDaySelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.timer_outlined, 'Payment Due'),
          const SizedBox(height: 12),
          Row(
            children: [7, 15, 30].map((d) {
              final sel = _dueDays == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _dueDays = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? _primary : _greyLight,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: _primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$d',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: sel ? _white : _accent,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          'days',
                          style: TextStyle(
                            fontSize: 11,
                            color: sel ? _white.withOpacity(0.8) : _grey,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Due: ${_formatDate(_dueDate)}',
            style: const TextStyle(
              fontSize: 12,
              color: _grey,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── Services Section ──────────────────────────────────
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              _sectionLabel(Icons.bolt_rounded, 'Service Charges'),
              const Spacer(),
              GestureDetector(
                onTap: _showServicePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _dark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: _white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Add Service',
                        style: TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_lines.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.15), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 40,
                  color: _primary.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap "Add Service" to begin',
                  style: TextStyle(
                    color: _grey,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          )
        else
          ..._lines.asMap().entries.map(
            (e) => _buildServiceLine(e.key, e.value),
          ),
      ],
    );
  }

  Widget _buildServiceLine(int idx, _ServiceLine line) {
    final svc = line.service;
    final isFixed = svc.isFixed;
    final qty = double.tryParse(line.ctrl.text) ?? 0;
    final amount = isFixed ? svc.unitPrice : qty * svc.unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, _dark]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _serviceIcon(svc.serviceName),
                        color: _primary,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            svc.serviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              color: _darkDeep,
                            ),
                          ),
                          if (svc.description != null &&
                              svc.description!.isNotEmpty)
                            Text(
                              svc.description!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _grey,
                                fontFamily: 'Inter',
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeLine(idx),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isFixed)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: _primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Fixed fee',
                          style: TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatVnd(svc.unitPrice.toInt()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _darkDeep,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _sand,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _greyLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: line.ctrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: TextStyle(color: _grey),
                                  ),
                                ),
                              ),
                              if (svc.unit != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    svc.unit!,
                                    style: const TextStyle(
                                      color: _grey,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '× ${_formatVnd(svc.unitPrice.toInt())}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _grey,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '= ${_formatVnd(amount.toInt())}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _darkDeep,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
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

  // ── Subtotal Card ─────────────────────────────────────
  Widget _buildSubtotalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _dark, _darkDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          ..._lines.map((l) {
            final qty = double.tryParse(l.ctrl.text) ?? 0;
            final amt = l.service.isFixed
                ? l.service.unitPrice
                : qty * l.service.unitPrice;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    _serviceIcon(l.service.serviceName),
                    size: 13,
                    color: _white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.service.isFixed
                        ? l.service.serviceName
                        : '${l.service.serviceName}: $qty ${l.service.unit ?? ''}',
                    style: TextStyle(
                      color: _white.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatVnd(amt.toInt()),
                    style: TextStyle(
                      color: _white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(color: _white.withOpacity(0.2), height: 20),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),
              Text(
                _formatVnd(_subtotal.toInt()),
                style: const TextStyle(
                  color: _white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────
  Widget _buildSubmitFab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _submitting ? null : _submit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _dark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _submitting
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
                      'Create Invoice',
                      style: TextStyle(
                        color: _white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Service Picker ────────────────────────────────────
  void _showServicePicker() {
    final available = _allServices
        .where((s) => !_lines.any((l) => l.service.id == s.id))
        .toList();
    if (available.isEmpty) {
      _showSnack('All services already added');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header cố định — không cuộn
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _greyLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Service',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: _darkDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to add to invoice',
                    style: TextStyle(
                      fontSize: 12,
                      color: _grey,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            // List cuộn được khi có nhiều service
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final svc = available[i];
                  return GestureDetector(
                    onTap: () {
                      _addService(svc);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _sand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _greyLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _serviceIcon(svc.serviceName),
                              color: _primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  svc.serviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    color: _darkDeep,
                                  ),
                                ),
                                Text(
                                  svc.isFixed
                                      ? 'Fixed: ${_formatVnd(svc.unitPrice.toInt())}'
                                      : '${_formatVnd(svc.unitPrice.toInt())} / ${svc.unit ?? 'unit'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _grey,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: svc.isFixed
                                  ? const Color(0xFFE0E7FF)
                                  : _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              svc.isFixed ? 'Fixed' : svc.serviceType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: svc.isFixed
                                    ? const Color(0xFF4338CA)
                                    : _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────
  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: _grey),
        const SizedBox(height: 12),
        Text(
          _error ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _grey, fontFamily: 'Inter'),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _loadingInit = true;
              _error = null;
            });
            _loadInit();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: _white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Helpers ───────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionLabel(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 15, color: _primary),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _primary,
          fontFamily: 'Inter',
        ),
      ),
    ],
  );

  Widget _infoBadge(String text) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: _primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: _primary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _primary, size: 22),
    ),
  );

  IconData _serviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('electric') || n.contains('điện')) return Icons.bolt_rounded;
    if (n.contains('water') || n.contains('nước'))
      return Icons.water_drop_rounded;
    if (n.contains('park') || n.contains('xe'))
      return Icons.directions_car_rounded;
    if (n.contains('internet') || n.contains('wifi')) return Icons.wifi_rounded;
    if (n.contains('clean') || n.contains('vệ sinh'))
      return Icons.cleaning_services_rounded;
    return Icons.miscellaneous_services_rounded;
  }

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

class _ServiceLine {
  final ServiceModel service;
  final TextEditingController ctrl;
  _ServiceLine({required this.service})
    : ctrl = TextEditingController(text: service.isFixed ? '1' : '');
}
