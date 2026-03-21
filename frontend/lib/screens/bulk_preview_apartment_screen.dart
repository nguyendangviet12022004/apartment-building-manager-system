import 'package:flutter/material.dart';
import '../services/api_apartment_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BulkPreviewApartmentScreen extends StatefulWidget {
  final int blockId;
  final String blockCode;
  final int floor;
  final List<Map<String, dynamic>> units;

  const BulkPreviewApartmentScreen({
    Key? key,
    required this.blockId,
    required this.blockCode,
    required this.floor,
    required this.units,
  }) : super(key: key);

  @override
  State<BulkPreviewApartmentScreen> createState() => _BulkPreviewApartmentScreenState();
}

class _BulkPreviewApartmentScreenState extends State<BulkPreviewApartmentScreen> {
  final ApiApartmentService _apiService = ApiApartmentService();
  
  final Color primaryMaroon = const Color(0xFF7A2A46);
  final Color backgroundLight = const Color(0xFFFDF8F9);
  final Color badgePink = const Color(0xFFF6D7DF);
  final Color inputFillColor = const Color(0xFFE8E8E8);

  late List<Map<String, dynamic>> _units;
  late List<TextEditingController> _controllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _units = List.from(widget.units.map((u) => Map<String, dynamic>.from(u)));
    _controllers = [];
    for (var unit in _units) {
      final ctrl = TextEditingController(text: unit['area']?.toString() ?? '0.0');
      _controllers.add(ctrl);
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String _generatePreviewCode(String blockCode, int floor, int unitIndex) {
    String floorPart = floor.toString().padLeft(2, '0') + unitIndex.toString().padLeft(2, '0');
    String base = '$blockCode-$floorPart';
    
    int sum = 0;
    for (int i = 0; i < base.length; i++) {
      sum += base.codeUnitAt(i);
    }
    
    String checksum = sum.toRadixString(16).toUpperCase();
    while (checksum.length < 3) checksum = '0' + checksum;
    if (checksum.length > 3) checksum = checksum.substring(checksum.length - 3);
    
    return '$base-$checksum';
  }

  void _validateUnitArea(int index, String value) {
    setState(() {
      if (value.isEmpty) {
        _units[index]['errorMessage'] = 'Area must be greater than 0';
      } else {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) {
          _units[index]['errorMessage'] = 'Area must be greater than 0';
        } else {
          _units[index]['errorMessage'] = null;
          _units[index]['area'] = parsed;
        }
      }
    });
  }

  Future<void> _submitAll() async {
    // Validate all rows
    bool hasError = false;
    for (int i = 0; i < _units.length; i++) {
        _validateUnitArea(i, _controllers[i].text);
        if (_units[i]['errorMessage'] != null) {
            hasError = true;
        }
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix invalid areas before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
      
      List<Map<String, dynamic>> unitsPayload = _units.map((u) {
        return {
          'area': u['area'],
        };
      }).toList();

      await _apiService.bulkCreateApartments(
        token: token,
        blockId: widget.blockId,
        floor: widget.floor,
        units: unitsPayload,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Apartments created successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text('OK', style: TextStyle(color: primaryMaroon)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create apartments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview & Edit Units',
          style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        // Header Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          decoration: BoxDecoration(
                            color: badgePink,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.business, color: primaryMaroon, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Block ${widget.blockCode} | Floor ${widget.floor.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: primaryMaroon, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_units.length} Units identified for editing',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // List of Units
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _units.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            Map<String, dynamic> unit = _units[index];
                            String apartmentCode = _generatePreviewCode(widget.blockCode, widget.floor, unit['index']);
                            bool hasError = unit['errorMessage'] != null;

                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: hasError ? Colors.red : Colors.transparent, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Code & Status
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              apartmentCode,
                                              style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.w900, fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgePink,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text('READY', style: TextStyle(color: primaryMaroon, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text('Standard 2-Bedroom', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                        if (hasError) ...[
                                          const SizedBox(height: 8),
                                          Text(unit['errorMessage'], style: const TextStyle(color: Colors.red, fontSize: 12)),
                                        ]
                                      ],
                                    ),
                                  ),
                                  
                                  // Area Input
                                  Container(
                                    width: 100,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: inputFillColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _controllers[index],
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold, fontSize: 16),
                                            onChanged: (val) => _validateUnitArea(index, val),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('m2', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Bottom Submit Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    onPressed: _submitAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Confirm & Save All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 12),
                        Icon(Icons.save, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
       bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryMaroon,
        unselectedItemColor: Colors.black54,
        currentIndex: 1, // Services is active
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Invoices'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
