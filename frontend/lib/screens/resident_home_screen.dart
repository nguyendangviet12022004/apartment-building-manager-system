import 'package:flutter/material.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_drawer.dart';
import '../routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/bills_page.dart';
import '../screens/payment_history_screen.dart';

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(child: Body()),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  static const _blue = Color(0xFF2845D6);
  static const _orange = Color(0xFFF68048);
  static const _grey = Color(0xFF9CA3AF);
  static const _darkText = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header + QuickActions overlap via Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeader(),
            Positioned(
              bottom: -48,
              left: 0,
              right: 0,
              child: _buildQuickActions(),
            ),
          ],
        ),
        // Spacer to compensate for the overlap
        const SizedBox(height: 64),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildAmenitiesBanner(),
                const SizedBox(height: 20),
                _buildNotifications(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildBottomNav(context),
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
          colors: [Color(0xFF2845D6), Color(0xFF0D1A63)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      // Extra bottom padding to make room for the overlapping card
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 45),
      child: Column(
        children: [
          // Top row: avatar + name + icons
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: const NetworkImage(
                  'https://via.placeholder.com/48.png', 
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
              const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const NotificationBell(
                iconColor: Colors.white,
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Apartment card
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apartment',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Text(
                          '#A-1205',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Floor 12',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Text(
                          'Skyline Tower',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        'Number of Occupants',
                        '4',
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Amount Due', '2.000.000đ', _orange),
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

  // ── Quick Actions (overlaps header) ─────────────────────
  Widget _buildQuickActions() {
    final actions = [
      (Icons.credit_card, 'My Bills', AppRoutes.bills),
      (Icons.calendar_today, 'Booking', null),
      (Icons.newspaper, 'News', null),
      (Icons.chat_bubble_outline, 'Feedback', null),
      (Icons.inventory_2_outlined, 'Parcels', AppRoutes.paymentHistory),
      (Icons.chat_bubble_outline, 'Requests', AppRoutes.requestList),
      (Icons.inventory_2_outlined, 'Parcels', null),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Builder(
        builder: (context) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: actions
              .map((a) => _buildActionItem(context, a.$1, a.$2, a.$3))
              .toList(),
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
    return GestureDetector(
      onTap: () => _onActionTap(context, route, label),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _blue, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  void _onActionTap(BuildContext context, String? route, String label) {
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

    if (route == AppRoutes.bills) {
      final apartmentId = context.read<AuthProvider>().apartmentId;
      if (apartmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apartment not verified yet'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      // Dùng Navigator.push trực tiếp — tránh conflict với Consumer rebuild
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillsPage(apartmentId: apartmentId)),
      );
      return;
    }

    if (route == AppRoutes.paymentHistory) {
      final apartmentId = context.read<AuthProvider>().apartmentId;
      if (apartmentId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Apartment not found')));
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentHistoryScreen(apartmentId: apartmentId),
        ),
      );
      return;
    }

    Navigator.pushNamed(context, route);
  }

  // ── Amenities Banner ─────────────────────────────────────
  Widget _buildAmenitiesBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 128,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://via.placeholder.com/327x128.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.2),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Amenities',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Book gym, pool & more',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Explore Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
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
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://via.placeholder.com/256x128.png'),
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

  Widget _buildBottomNav(BuildContext context) {
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
              return GestureDetector(
                onTap: () {
                  if (item.$2 == 'Home') {
                    // Already on Home
                  } else if (item.$2 == 'Services') {
                    _onActionTap(context, null, item.$2);
                  } else if (item.$2 == 'Invoices') {
                    _onActionTap(context, AppRoutes.bills, item.$2);
                  } else if (item.$2 == 'Profile') {
                    Navigator.pushNamed(context, AppRoutes.profile);
                  }
                },
                child: Column(
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
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
