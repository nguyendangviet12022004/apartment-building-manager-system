// lib/screens/admin_home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/create_invoice_page.dart';
import '../routes/app_routes.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: SafeArea(child: Body()),
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  static const _primary = Color(0xFF88304E);
  static const _dark = Color(0xFF522546);
  static const _orange = Color(0xFFF68048);
  static const _blue = Color(0xFF2845D6);
  static const _grey = Color(0xFF9CA3AF);
  static const _darkText = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    const double overlapAmount = 155;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeader(),
            Positioned(
              bottom: -overlapAmount,
              left: 0,
              right: 0,
              child: _buildQuickActions(),
            ),
          ],
        ),
        const SizedBox(height: overlapAmount),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildNotifications(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildBottomNav(),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.35, 0.35),
          end: Alignment(1.06, -0.35),
          colors: [_primary, _dark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: const NetworkImage(
                  'https://placehold.co/48x48',
                ),
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Text(
                      'Sarah Johnson',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.qr_code_2, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 26,
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAptText('Role', 'Manager', CrossAxisAlignment.start),
                    _buildAptText(
                      'Floor 12',
                      'Skyline Tower',
                      CrossAxisAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        'Total Residents',
                        '4',
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        'Outstanding Payments',
                        '2.000.000đ',
                        _orange,
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

  Widget _buildAptText(String label, String value, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────────────
  // 👇 Invoice route thay đổi từ AppRoutes.createInvoice → AppRoutes.invoiceList
  static const _row1 = [
    (Icons.receipt_long, 'Invoice', AppRoutes.invoiceList), // ← updated
    (Icons.spa_outlined, 'Amenity', null),
    (Icons.newspaper, 'News', null),
    (Icons.bar_chart, 'Report', null),
    (Icons.people_outline, 'Resident', AppRoutes.residentManagement),
  ];

  static const _row2 = [
    (Icons.apartment, 'Apartment', null),
    (Icons.directions_car_outlined, 'Vehicle', null),
  ];

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Builder(
        builder: (ctx) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _row1
                  .map((e) => _buildActionItem(ctx, e.$1, e.$2, e.$3))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _row2
                  .map((e) => _buildActionItem(ctx, e.$1, e.$2, e.$3))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    String? route,
  ) {
    return SizedBox(
      width: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (route == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label — Coming soon'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
              return;
            }
            Navigator.of(context, rootNavigator: true).pushNamed(route);
          },
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Notifications ────────────────────────────────────────
  static const _notifs = [
    ('Elevator Maintenance', 'Schedule: Dec 15-16'),
    ('Holiday Celebrations', 'Join us Dec 24th'),
    ('Pool Hours Extended', 'Now open until 11 PM'),
  ];

  Widget _buildNotifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Notifications',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _notifs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  _buildNotifCard(_notifs[i].$1, _notifs[i].$2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(String title, String subtitle) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://placehold.co/256x128'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────
  static const _navItems = [
    (Icons.home, 'Home', true),
    (Icons.grid_view, 'Services', false),
    (Icons.receipt_long, 'Invoices', false),
    (Icons.person_outline, 'Profile', false),
  ];

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.map((item) {
              final color = item.$3 ? _blue : _grey;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, color: color, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: item.$3 ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
