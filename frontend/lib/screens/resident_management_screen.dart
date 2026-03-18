import 'package:flutter/material.dart';
import '../models/resident_model.dart';
import '../models/block_model.dart';
import '../services/resident_service.dart';
import '../services/block_service.dart';

class ResidentManagementScreen extends StatefulWidget {
  const ResidentManagementScreen({super.key});

  @override
  State<ResidentManagementScreen> createState() =>
      _ResidentManagementScreenState();
}

class _ResidentManagementScreenState extends State<ResidentManagementScreen> {
  final ResidentService _residentService = ResidentService();
  final BlockService _blockService = BlockService();
  final TextEditingController _searchController = TextEditingController();

  List<ResidentModel> _residents = [];
  List<BlockModel> _blocks = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedBuilding;
  String? _selectedStatus;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadBlocks();
    _loadResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlocks() async {
    try {
      final blocks = await _blockService.getAllBlocks();
      setState(() {
        _blocks = blocks;
      });
    } catch (e) {
      // Silently fail, user can still use the app without block filter
      print('Failed to load blocks: $e');
    }
  }

  Future<void> _loadResidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _residentService.getResidents(
        search: _searchController.text.trim(),
        building: _selectedBuilding,
        status: _selectedStatus,
        type: _selectedType,
      );

      setState(() {
        _residents = response.residents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        _loadResidents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF88304E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Resident Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _residents.isEmpty
                        ? _buildEmptyState()
                        : _buildResidentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF88304E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _showFilterDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Building',
                  value: _selectedBuilding,
                  onTap: () => _showBuildingFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Status',
                  value: _selectedStatus,
                  onTap: () => _showStatusFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Type',
                  value: _selectedType,
                  onTap: () => _showTypeFilter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFFCE7F3) : Colors.white,
          border: Border.all(
            color: hasValue ? const Color(0xFF88304E) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasValue ? '$label: $value' : label,
              style: TextStyle(
                color: hasValue ? const Color(0xFF88304E) : const Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: hasValue ? const Color(0xFF88304E) : const Color(0xFF6B7280),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentList() {
    return RefreshIndicator(
      onRefresh: _loadResidents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _residents.length,
        itemBuilder: (context, index) {
          final resident = _residents[index];
          return _buildResidentCard(resident);
        },
      ),
    );
  }

  Widget _buildResidentCard(ResidentModel resident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF88304E),
                backgroundImage: resident.avatarUrl != null
                    ? NetworkImage(resident.avatarUrl!)
                    : null,
                child: resident.avatarUrl == null
                    ? Text(
                        resident.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
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
                            resident.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: resident.isActive
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resident.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: resident.isActive
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resident.ownershipType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF88304E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details
          Row(
            children: [
              const Icon(Icons.apartment, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                resident.apartmentCode != null
                    ? 'Bldg ${resident.blockCode ?? ''} - Unit ${resident.apartmentCode}'
                    : 'No apartment assigned',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                resident.phone ?? 'No phone',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // View Profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to resident profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('View profile: ${resident.fullName}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF88304E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'View Profile',
                style: TextStyle(
                  color: Color(0xFF88304E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No residents found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unable to load resident list',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadResidents,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF88304E),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // Show comprehensive filter dialog
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Clear all filters'),
              trailing: const Icon(Icons.clear_all),
              onTap: () {
                setState(() {
                  _selectedBuilding = null;
                  _selectedStatus = null;
                  _selectedType = null;
                });
                Navigator.pop(context);
                _loadResidents();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Buildings'),
              onTap: () {
                setState(() => _selectedBuilding = null);
                Navigator.pop(context);
                _loadResidents();
              },
            ),
            ..._blocks.map((block) => ListTile(
              title: Text('Building ${block.blockCode}'),
              onTap: () {
                setState(() => _selectedBuilding = block.blockCode);
                Navigator.pop(context);
                _loadResidents();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Status'),
              onTap: () {
                setState(() => _selectedStatus = null);
                Navigator.pop(context);
                _loadResidents();
              },
            ),
            ListTile(
              title: const Text('Active'),
              onTap: () {
                setState(() => _selectedStatus = 'ACTIVE');
                Navigator.pop(context);
                _loadResidents();
              },
            ),
            ListTile(
              title: const Text('Inactive'),
              onTap: () {
                setState(() => _selectedStatus = 'INACTIVE');
                Navigator.pop(context);
                _loadResidents();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Types'),
              onTap: () {
                setState(() => _selectedType = null);
                Navigator.pop(context);
                _loadResidents();
              },
            ),
            ListTile(
              title: const Text('Owner'),
              onTap: () {
                setState(() => _selectedType = 'OWNER');
                Navigator.pop(context);
                _loadResidents();
              },
            ),
            ListTile(
              title: const Text('Tenant'),
              onTap: () {
                setState(() => _selectedType = 'TENANT');
                Navigator.pop(context);
                _loadResidents();
              },
            ),
          ],
        ),
      ),
    );
  }
}
