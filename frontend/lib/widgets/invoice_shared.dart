import 'package:flutter/material.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class AppColors {
  static const background = Color(0xFFF5F5F5);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const accent = Color(0xFF88304E);
  static const accentLight = Color(0x1A88304E);
  static const slate = Color(0xFF4B5563);
  static const gray = Color(0xFF9CA3AF);
  static const lightGray = Color(0xFFE5E7EB);

  static const overdueRed = Color(0xFFDC2626);
  static const paidGreen = Color(0xFF16A34A);
  static const unpaidAmber = Color(0xFFD97706);

  static const warningBg = Color(0xFFFFF7ED);
  static const warningBorder = Color(0xFFFED7AA);
  static const warningText = Color(0xFF92400E);
}

// ─── Model ────────────────────────────────────────────────────────────────────
class Invoice {
  final String apt;
  final String initials;
  final int amount;
  final String status; // 'overdue', 'paid', 'unpaid'
  final int? monthsOverdue;

  const Invoice({
    required this.apt,
    required this.initials,
    required this.amount,
    required this.status,
    this.monthsOverdue,
  });
}

final mockInvoices = [
  const Invoice(apt: 'A501', initials: 'NA', amount: 360000, status: 'overdue', monthsOverdue: 2),
  const Invoice(apt: 'A502', initials: 'TH', amount: 480000, status: 'overdue', monthsOverdue: 3),
  const Invoice(apt: 'A503', initials: 'LM', amount: 360000, status: 'overdue', monthsOverdue: 2),
  const Invoice(apt: 'A504', initials: 'BN', amount: 360000, status: 'overdue', monthsOverdue: 1),
  const Invoice(apt: 'A505', initials: 'PQ', amount: 0, status: 'paid', monthsOverdue: null),
  const Invoice(apt: 'B101', initials: 'VT', amount: 720000, status: 'unpaid', monthsOverdue: null),
];

// ─── Helper ───────────────────────────────────────────────────────────────────
String formatVnd(int amount) {
  final s = amount.toString();
  final result = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) result.write('.');
    result.write(s[i]);
    count++;
  }
  return result.toString().split('').reversed.join();
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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

class InvoiceRowItem extends StatelessWidget {
  final String invId;
  final String month;
  final int amount;
  final String status;
  final Color statusColor;

  const InvoiceRowItem({
    super.key,
    required this.invId,
    required this.month,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invId,
                style: const TextStyle(
                  color: AppColors.gray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                month,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${formatVnd(amount)}đ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ReminderToggle extends StatefulWidget {
  final IconData icon;
  final String label;

  const ReminderToggle({super.key, required this.icon, required this.label});

  @override
  State<ReminderToggle> createState() => _ReminderToggleState();
}

class _ReminderToggleState extends State<ReminderToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _enabled ? AppColors.accentLight : AppColors.lightGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _enabled ? AppColors.accent : AppColors.gray,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _enabled ? AppColors.black : AppColors.gray,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _enabled = !_enabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: _enabled ? AppColors.accent : AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}