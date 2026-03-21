import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_apartment_service.dart';
import 'apartment_detail_screen.dart';

class ApartmentListScreen extends StatefulWidget {
  const ApartmentListScreen({super.key});

  @override
  State<ApartmentListScreen> createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  final ApiApartmentService _apiService = ApiApartmentService();

  List<dynamic> _apartments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String _searchQuery = '';
  String _selectedStatus = 'All Units'; // All Units, Occupied, Vacant, Fixing

  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  final Color _primaryMaroon = const Color(0xFF7A2A46);
  final Color _backgroundPink = const Color(0xFFFDF8F9);

  @override
  void initState() {
    super.initState();
    _fetchApartments();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          !_isLastPage) {
        _loadMoreApartments();
      }
    });
  }

  Future<void> _fetchApartments({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _isLastPage = false;
        _apartments = [];
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
      String? filterStatus;
      if (_selectedStatus != 'All Units') {
        filterStatus = _selectedStatus.toUpperCase();
      }

      final response = await _apiService.getApartments(
        token: token,
        keyword: _searchQuery,
        status: filterStatus,
        page: _currentPage,
        size: 10,
      );

      final List<dynamic> content = response['content'] ?? [];
      final bool last = response['last'] ?? true;

      setState(() {
        if (reset) {
          _apartments = content;
        } else {
          _apartments.addAll(content);
        }
        _isLastPage = last;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load apartment list';
      });
    }
  }

  Future<void> _loadMoreApartments() async {
    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _fetchApartments(reset: false);

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _fetchApartments(reset: true);
  }

  void _onStatusChanged(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _fetchApartments(reset: true);
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Skyline Velvet',
          style: TextStyle(
            color: Color(0xFF7A2A46),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DIRECTORY',
                  style: TextStyle(
                    color: Color(0xFFC07B8C),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Apartments',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      // Debounce would be nice, but straightforward call is sufficient
                      _onSearchChanged(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search apartment code...',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All Units'),
                      const SizedBox(width: 12),
                      _buildFilterButton('Occupied'),
                      const SizedBox(width: 12),
                      _buildFilterButton('Vacant'),
                      const SizedBox(width: 12),
                      _buildFilterButton('Fixing'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List Content
          Expanded(child: _buildListContent()),
        ],
      ),
      // Mock Bottom Nav Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: _primaryMaroon,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title) {
    bool isSelected = _selectedStatus == title;
    return GestureDetector(
      onTap: () => _onStatusChanged(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryMaroon : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryMaroon.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: isSelected ? null : Border.all(color: Colors.black12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
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
              onPressed: () => _fetchApartments(reset: true),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryMaroon),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_apartments.isEmpty) {
      return const Center(
        child: Text(
          "No apartments found",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _apartments.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _apartments.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: _primaryMaroon),
            ),
          );
        }
        return _buildApartmentCard(_apartments[index]);
      },
    );
  }

  String _normalizeStatus(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return 'VACANT';
    final upper = rawStatus.toUpperCase().trim();
    if (upper == 'AVAILABLE' || upper == 'VACANT') return 'VACANT';
    if (upper == 'OCCUPIED') return 'OCCUPIED';
    if (upper == 'FIXING' || upper == 'MAINTENANCE') return 'FIXING';
    return upper;
  }

  Widget _buildStatusBadge(String rawStatus) {
    final status = _normalizeStatus(rawStatus);
    Color bgColor;
    Color textColor;
    String label;
    if (status == 'OCCUPIED') {
      bgColor = const Color(0xFFFFEAEA);
      textColor = const Color(0xFFB84566); // match red
      label = 'Occupied';
    } else if (status == 'FIXING') {
      bgColor = const Color(0xFFFFF4E5);
      textColor = const Color(0xFFE6A23C); // match orange
      label = 'Fixing';
    } else {
      bgColor = const Color(0xFFE6F4EA);
      textColor = const Color(0xFF1E8E3E); // match green
      label = 'Vacant';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApartmentCard(Map<String, dynamic> apt) {
    // Fallback if area is null or different format
    final dynamic areaRaw = apt['area'];
    final String areaStr = areaRaw != null ? areaRaw.toString() : '0.0';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApartmentDetailScreen(apartmentId: apt['id']),
          ),
        );
        if (result == true && mounted) {
          _fetchApartments(reset: true);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt['apartmentCode'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BLOCK ${apt['blockCode'] ?? '?'} • FLOOR ${apt['floor'] ?? '?'}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(apt['status']),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL AREA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$areaStr m²',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Standard', // Currently static as backend does not contain category
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
