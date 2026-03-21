import 'package:flutter/material.dart';
import '../services/api_block_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'bulk_preview_apartment_screen.dart';

class BulkCreateApartmentScreen extends StatefulWidget {
  const BulkCreateApartmentScreen({Key? key}) : super(key: key);

  @override
  State<BulkCreateApartmentScreen> createState() => _BulkCreateApartmentScreenState();
}

class _BulkCreateApartmentScreenState extends State<BulkCreateApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiBlockService _blockService = ApiBlockService();
  
  final Color primaryMaroon = const Color(0xFF7A2A46);
  final Color backgroundLight = const Color(0xFFFDF8F9);
  final Color cardBackground = Colors.white;
  final Color badgePink = const Color(0xFFF6D7DF);
  final Color inputFillColor = const Color(0xFFE8E8E8);

  String? blockId;
  String? blockCodeName; 
  int? floor;
  int? unitsCount;
  double? averageArea;

  bool _isLoadingBlocks = true;
  List<Map<String, dynamic>> _blocks = [];

  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBlocks();
    });
  }

  @override
  void dispose() {
    _floorController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlocks() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
      final data = await _blockService.getBlocks(token: token);
      if (mounted) {
        setState(() {
          _blocks = data;
          _isLoadingBlocks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBlocks = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load blocks: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _generatePreview() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      List<Map<String, dynamic>> previewUnits = [];
      for (int i = 1; i <= unitsCount!; i++) {
        previewUnits.add({
          'index': i,
          'area': averageArea,
          'errorMessage': null,
        });
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BulkPreviewApartmentScreen(
            blockId: int.parse(blockId!),
            blockCode: blockCodeName ?? '',
            floor: floor!,
            units: previewUnits,
          ),
        ),
      );
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
          'Bulk Import Apartments',
          style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoadingBlocks
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Text
                    Text('Floor Setup', style: TextStyle(color: primaryMaroon, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Configure units for your building layout', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    const SizedBox(height: 24),

                    // Setup Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Select Block
                          _buildLabel('SELECT BLOCK'),
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Grand Sapphire Tower'),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                            items: _blocks.map((b) {
                              return DropdownMenuItem<String>(
                                value: b['id'].toString(),
                                child: Text(b['blockCode'] != null ? '${b['blockCode']} - ${b['description'] ?? 'Block'}' : 'Unnamed Block'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                blockId = val;
                                final b = _blocks.firstWhere((element) => element['id'].toString() == val);
                                blockCodeName = b['blockCode'];
                              });
                            },
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 24),

                          // Floor Number
                          _buildLabel('FLOOR NUMBER'),
                          TextFormField(
                            controller: _floorController,
                            decoration: _inputDecoration('e.g. 12').copyWith(
                              prefixIcon: Icon(Icons.layers, color: primaryMaroon, size: 20),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {}),
                            onSaved: (val) => floor = int.tryParse(val ?? '0'),
                            validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) ? 'Required > 0' : null,
                          ),
                          const SizedBox(height: 24),

                          // Number of Units
                          _buildLabel('NUMBER OF UNITS'),
                          TextFormField(
                            controller: _unitsController,
                            decoration: _inputDecoration('e.g. 8').copyWith(
                              prefixIcon: Icon(Icons.business, color: primaryMaroon, size: 20),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {}),
                            onSaved: (val) => unitsCount = int.tryParse(val ?? '0'),
                            validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) ? 'Required > 0' : null,
                          ),
                          const SizedBox(height: 24),

                          // Average Area
                          _buildLabel('AVERAGE AREA (m2)'),
                          TextFormField(
                            decoration: _inputDecoration('e.g. 70.0').copyWith(
                              prefixIcon: Icon(Icons.square_foot, color: primaryMaroon, size: 20),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => averageArea = double.tryParse(val ?? '0.0'),
                            validator: (val) => (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) <= 0) ? 'Required > 0' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Box pink
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: badgePink,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(Icons.auto_awesome, color: primaryMaroon, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Automated Sequence', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 8),
                                Text(
                                  'Generate unit numbers automatically based on the floor level. You can edit individual units in the next step.',
                                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Generate Button
                    ElevatedButton(
                      onPressed: _generatePreview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Generate Preview List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54, letterSpacing: 1.0)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
