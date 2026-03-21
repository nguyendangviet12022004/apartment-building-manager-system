import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../services/api_request_service.dart';
import '../providers/auth_provider.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final ApiRequestService _apiService = ApiRequestService();
  final ScrollController _scrollController = ScrollController();

  List<RequestModel> _requests = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 0;
  bool _hasMoreData = true;

  String _selectedStatus = 'All Status';
  String _selectedIssueType = 'Issue Type';
  String _selectedSort = 'Newest';

  final List<String> _statusOptions = [
    'All Status',
    'PENDING',
    'APPROVED',
    'REJECTED'
  ];

  final List<String> _issueTypeOptions = [
    'Issue Type',
    'Electrical',
    'Plumbing',
    'HVAC',
    'Maintenance',
    'Other'
  ];

  final List<String> _sortOptions = ['Newest', 'Oldest', 'Priority'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRequests(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMoreData) {
      _fetchRequests(refresh: false);
    }
  }

  Future<void> _fetchRequests({bool refresh = false}) async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    if (refresh) {
      setState(() {
        _page = 0;
        _isLoading = true;
        _errorMessage = null;
        _hasMoreData = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final newRequests = await _apiService.getMyRequests(
        token: token,
        status: _selectedStatus == 'All Status' ? null : _selectedStatus,
        issueType: _selectedIssueType == 'Issue Type' ? null : _selectedIssueType,
        sort: _selectedSort,
        page: _page,
        size: 20,
      );

      setState(() {
        if (refresh) {
          _requests = newRequests;
        } else {
          _requests.addAll(newRequests);
        }

        if (newRequests.length < 20) {
          _hasMoreData = false;
        } else {
          _page++;
        }

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Unable to load requests";
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Requests',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildBodyContent(),
          ),
          _buildBottomNav(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70), // offset for bottom nav
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0D47A1),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/create-request');
            if (result == true) {
              _fetchRequests(refresh: true);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDropdown(_selectedStatus, _statusOptions, (val) {
              setState(() => _selectedStatus = val!);
              _fetchRequests(refresh: true);
            }),
            const SizedBox(width: 8),
            _buildDropdown(_selectedIssueType, _issueTypeOptions, (val) {
              setState(() => _selectedIssueType = val!);
              _fetchRequests(refresh: true);
            }),
            const SizedBox(width: 8),
            _buildDropdown(_selectedSort, _sortOptions, (val) {
              setState(() => _selectedSort = val!);
              _fetchRequests(refresh: true);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF4B5563)),
          isDense: true,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          onChanged: onChanged,
          items: options.map((opt) {
            String label = opt;
            if (opt == 'PENDING') label = 'Pending';
            if (opt == 'APPROVED') label = 'Approved';
            if (opt == 'REJECTED') label = 'Rejected';
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(label),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchRequests(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          "No requests found",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchRequests(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _requests.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _requests.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildRequestCard(_requests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${request.id}',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              _buildStatusBadge(request.status.name),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            request.title,
            style: const TextStyle(
              color: Color(0xFF0D47A1),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (request.priority == 'HIGH')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEF4444)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text(
                        'HIGH PRIORITY',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(),
              Text(
                _formatDate(request.createdAt),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        text = 'PENDING';
        break;
      case 'APPROVED':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        text = 'APPROVED';
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        text = 'REJECTED';
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // ── Bottom Nav ───────────────────────────────────────────
  static const _navItems = [
    (Icons.home, 'Home', false),
    (Icons.build, 'Services', true),
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
              final color = item.$3 ? const Color(0xFF0D47A1) : const Color(0xFF9CA3AF);
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
