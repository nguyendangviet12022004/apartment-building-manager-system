import 'package:flutter/material.dart';
import '../services/api_apartment_service.dart';
import '../services/api_block_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'bulk_create_apartment_screen.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({Key? key}) : super(key: key);

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiApartmentService _apiService = ApiApartmentService();
  final ApiBlockService _blockService = ApiBlockService();
  
  // Theme colors extracted from your design
  final Color primaryMaroon = const Color(0xFF7A2A46);
  final Color backgroundPink = const Color(0xFFFDF8F9);
  final Color statusBoxFill = const Color(0xFFF5EFEF);

  // Form State
  String? blockId; // Maps to Block ID
  int? floor;
  double? area;
  String status = 'VACANT'; // Default

  bool _isLoading = false;
  bool _isLoadingBlocks = true;

  // Real blocks data from API
  List<Map<String, dynamic>> _blocks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBlocks();
    });
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      try {
        final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
        
        final responseData = await _apiService.createApartment(
          token: token,
          floor: floor!,
          area: area!,
          status: status,
          blockId: int.parse(blockId!),
        );

        if (!mounted) return;
        
        String createdCode = '';
        if (responseData.containsKey('apartmentCode')) {
            createdCode = responseData['apartmentCode'];
        } else if (responseData.containsKey('data') && responseData['data'] != null && responseData['data']['apartmentCode'] != null) {
            createdCode = responseData['data']['apartmentCode'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createdCode.isNotEmpty 
              ? "Apartment created successfully: $createdCode"
              : "Apartment created successfully"),
            backgroundColor: primaryMaroon,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Go back after success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        backgroundColor: primaryMaroon,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: const [
            Text('The Curator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('BUILDING MANAGEMENT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Titles
                    Center(
                      child: Text(
                        'INVENTORY MANAGEMENT',
                        style: TextStyle(
                          color: primaryMaroon,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Create New Unit',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Input architectural specifications to\nregister a new apartment into the Skyline\nsystem.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 24),



                    // Block Selection
                    _buildLabel('Block'),
                    _isLoadingBlocks 
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                      : DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Select Block'),
                          icon: Icon(Icons.keyboard_arrow_down, color: primaryMaroon),
                          items: _blocks.map((b) {
                            return DropdownMenuItem<String>(
                              value: b['id'].toString(),
                              child: Text(b['blockCode'] != null ? '${b['blockCode']} - ${b['description'] ?? 'Block'}' : 'Unnamed Block'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => blockId = val),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Block is required';
                            return null;
                          },
                        ),
                    const SizedBox(height: 16),

                    // Floor
                    _buildLabel('Floor'),
                    _buildTextField(
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(Icons.layers, color: Colors.black26),
                      onSaved: (val) => floor = int.tryParse(val ?? '0'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Floor is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area
                    _buildLabel('Area (sq. ft.)'),
                    _buildTextField(
                      hintText: '1200',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(Icons.architecture, color: Colors.black26),
                      onSaved: (val) => area = double.tryParse(val ?? '0.0'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Area is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Operational Status Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: statusBoxFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryMaroon,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.bar_chart, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 12),
                              const Text('Operational Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusOption(title: 'Occupied', subtitle: 'TENANT ACTIVE', value: 'OCCUPIED'),
                          const SizedBox(height: 12),
                          _buildStatusOption(title: 'Vacant', subtitle: 'READY FOR LISTING', value: 'VACANT'),
                          const SizedBox(height: 12),
                          _buildStatusOption(title: 'Fixing', subtitle: 'UNDER MAINTENANCE', value: 'FIXING'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Card Placeholder
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'), // Placeholder
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Colors.black87, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('PROPERTY LOCATION', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
                            SizedBox(height: 4),
                            Text('Central District Complex •\nPhase II', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Save Apartment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.verified, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: statusBoxFill, // matching the cancel button background
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Cancel', style: TextStyle(fontSize: 16, color: primaryMaroon, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BulkCreateApartmentScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: primaryMaroon, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_add, color: primaryMaroon, size: 18),
                          const SizedBox(width: 8),
                          Text('Bulk Import Apartments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryMaroon)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      // Mock Bottom Nav Bar 
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryMaroon,
        unselectedItemColor: Colors.black54,
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

  // Helper Widget Builders
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildTextField({required String hintText, Widget? suffixIcon, TextInputType? keyboardType, FormFieldSetter<String>? onSaved, FormFieldValidator<String>? validator}) {
    return TextFormField(
      decoration: _inputDecoration(hintText).copyWith(suffixIcon: suffixIcon),
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryMaroon, width: 2),
      ),
    );
  }

  Widget _buildStatusOption({required String title, required String subtitle, required String value}) {
    bool isSelected = status == value;
    return GestureDetector(
      onTap: () => setState(() => status = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryMaroon : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryMaroon : Colors.black26,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 10,  color: Colors.black54, letterSpacing: 0.5)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
