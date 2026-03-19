import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_apartment_service.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final int apartmentId;

  const ApartmentDetailScreen({super.key, required this.apartmentId});

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  final ApiApartmentService _apiService = ApiApartmentService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _apartmentDetail;

  final Color _primaryMaroon = const Color(0xFF7A2A46);
  final Color _backgroundPink = const Color(0xFFFDF8F9);
  final Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchApartmentDetail();
  }

  Future<void> _fetchApartmentDetail() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
      final data = await _apiService.getApartmentDetail(
        token: token,
        id: widget.apartmentId,
      );
      setState(() {
        _apartmentDetail = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load apartment details';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundPink,
      appBar: AppBar(
        backgroundColor: _backgroundPink,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7A2A46)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Apartment Details',
          style: TextStyle(
            color: Color(0xFF7A2A46),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF7A2A46), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF7A2A46), size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryMaroon));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _fetchApartmentDetail();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryMaroon),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_apartmentDetail == null) {
      return const Center(child: Text("No data found"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderImageCard(),
          const SizedBox(height: 16),
          _buildArchitectureCard(),
          const SizedBox(height: 16),
          _buildOwnershipCard(),
          const SizedBox(height: 16),
          if (_apartmentDetail!['residentId'] != null) ...[
             _buildResidentCard(),
             const SizedBox(height: 16),
          ],
          _buildUtilityCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderImageCard() {
    final String aptCode = _apartmentDetail!['apartmentCode'] ?? 'Unknown';
    final String status = _apartmentDetail!['status'] ?? 'Vacant';
    final bool isOccupied = status.toUpperCase() == 'OCCUPIED';

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryMaroon.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'UNIT $aptCode',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: const Text(
                    'Apartment\nDetails',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.greenAccent : Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOccupied ? 'Occupied' : 'Vacant',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectureCard() {
    final String internalCode = _apartmentDetail!['apartmentCode'] ?? '-';
    final String block = _apartmentDetail!['blockCode'] ?? '?';
    final int floor = _apartmentDetail!['floor'] ?? 0;
    
    final dynamic areaRaw = _apartmentDetail!['area'];
    final String areaStr = areaRaw != null ? areaRaw.toString() : '0.0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Building Architecture',
                style: TextStyle(color: _primaryMaroon, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Icon(Icons.business, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoItem('INTERNAL CODE', internalCode)),
              Expanded(child: _buildInfoItem('WING / BLOCK', 'Block $block')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoItem('FLOOR LEVEL', '${floor}th Floor')),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL AREA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: areaStr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                        children: const [
                          TextSpan(text: ' m²', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildOwnershipCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryMaroon,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _primaryMaroon.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ownership', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('STATUS AND TIMELINE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.0)),
                ],
              ),
              Icon(Icons.verified_user, color: Colors.white.withOpacity(0.2), size: 36),
            ],
          ),
          const SizedBox(height: 24),
          _buildDarkInnerCard('TYPE', 'Standard'),
          const SizedBox(height: 12),
          _buildDarkInnerCard('STATUS', _apartmentDetail!['status'] ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildDarkInnerCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResidentCard() {
    final String residentName = _apartmentDetail!['residentName'] ?? 'No Resident';
    final String residentEmail = _apartmentDetail!['residentEmail'] ?? '-';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: _backgroundPink, width: 3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(residentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 4),
                    const Text('Primary Resident', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactRow(Icons.phone, 'PHONE', '+1 (Not provided)'), // Email is provided, phone isn't typical in DTO but following design
          const SizedBox(height: 16),
          _buildContactRow(Icons.email, 'EMAIL', residentEmail),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _backgroundPink,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _primaryMaroon, size: 16),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1.0)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Utility\nEfficiency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text('Real-time\nconsumption metrics', style: TextStyle(fontSize: 10, color: Colors.black45)),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('98.4%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _primaryMaroon)),
                  const SizedBox(width: 4),
                  Icon(Icons.trending_up, color: _primaryMaroon, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _primaryMaroon,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
