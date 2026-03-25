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
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
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
          SnackBar(
            content: Text('Failed to load blocks: $e'),
            backgroundColor: Colors.red,
          ),
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
        final token =
            Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';

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
        } else if (responseData.containsKey('data') &&
            responseData['data'] != null &&
            responseData['data']['apartmentCode'] != null) {
          createdCode = responseData['data']['apartmentCode'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createdCode.isNotEmpty
                  ? "Apartment created successfully: $createdCode"
                  : "Apartment created successfully",
            ),
            backgroundColor: primaryMaroon,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Go back after success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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

  void _showManageBlocksBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.domain, color: primaryMaroon),
                            const SizedBox(width: 12),
                            Text(
                              'Building Blocks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryMaroon,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            _showAddOrEditBlockDialog(null, setModalState);
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: backgroundPink,
                            child: Icon(Icons.add, color: primaryMaroon),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoadingBlocks
                        ? Center(child: CircularProgressIndicator(color: primaryMaroon))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _blocks.length,
                            separatorBuilder: (context, index) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final block = _blocks[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: backgroundPink,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.business, color: primaryMaroon),
                                ),
                                title: Text(
                                  block['blockCode'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  (block['description']?.toString().isEmpty ?? true)
                                      ? 'NO DESCRIPTION'
                                      : block['description'].toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: primaryMaroon, size: 20),
                                      onPressed: () {
                                        _showAddOrEditBlockDialog(block, setModalState);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        _confirmDeleteBlock(block, setModalState);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _showAddOrEditBlockDialog(null, setModalState);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '+ Add Block',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _fetchBlocks();
    });
  }

  void _showPopupNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(isError ? 'Error' : 'Success', style: TextStyle(color: isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isError ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditBlockDialog(Map<String, dynamic>? block, StateSetter setModalState) {
    final isEdit = block != null;
    final codeController = TextEditingController(text: block?['blockCode']);
    final descController = TextEditingController(text: block?['description']);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Block' : 'Add Block', style: TextStyle(color: primaryMaroon)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeController,
                      decoration: _inputDecoration('Block Code (e.g. BLA)'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Code is required';
                        if (v.length != 3) return 'Code must be exactly 3 chars';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: _inputDecoration('Name/Description (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSaving = true);
                            try {
                              final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
                              if (isEdit) {
                                await _blockService.updateBlock(
                                  token: token,
                                  id: block['id'],
                                  blockCode: codeController.text,
                                  description: descController.text,
                                );
                              } else {
                                final newBlock = await _blockService.createBlock(
                                  token: token,
                                  blockCode: codeController.text,
                                  description: descController.text,
                                );
                                setState(() {
                                  blockId = newBlock['id'].toString();
                                });
                              }
                              
                              // Fetch fresh data
                              final data = await _blockService.getBlocks(token: token);
                              setModalState(() {
                                _blocks = data;
                              });
                              setState(() {
                                _blocks = data;
                                // ensure blockId is still valid
                                if (blockId != null && !_blocks.any((b) => b['id'].toString() == blockId)) {
                                  blockId = null;
                                }
                              });
                              
                              if (mounted) {
                                Navigator.pop(dialogContext); // close form on success
                                _showPopupNotification(isEdit ? 'Block updated successfully' : 'Block created successfully');
                              }
                            } catch (e) {
                              if (mounted) {
                                _showPopupNotification(e.toString().replaceAll('Exception: ', ''), isError: true);
                                setDialogState(() => isSaving = false); // stop loading indicator
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryMaroon),
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Save' : 'Create', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBlock(Map<String, dynamic> block, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Block'),
          content: Text('Are you sure you want to delete block "${block['blockCode']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
                Navigator.pop(dialogContext);
                try {
                  await _blockService.deleteBlock(token: token, id: block['id']);
                  if (!mounted) return;
                  _showPopupNotification('Block deleted successfully');
                  final data = await _blockService.getBlocks(token: token);
                  setModalState(() {
                    _blocks = data;
                  });
                  setState(() {
                    _blocks = data;
                    if (blockId == block['id'].toString()) blockId = null;
                  });
                } catch (e) {
                  if (!mounted) return;
                  _showPopupNotification(e.toString().replaceAll('Exception: ', ''), isError: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
            //   Text('The Curator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(
              'BUILDING MANAGEMENT',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 1.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Input architectural specifications to\nregister a new apartment into the ABMS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Block Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Block'),
                        if (!_isLoadingBlocks)
                          InkWell(
                            onTap: _showManageBlocksBottomSheet,
                            child: Row(
                              children: [
                                Icon(Icons.edit_note, size: 16, color: primaryMaroon),
                                const SizedBox(width: 4),
                                Text(
                                  'Manage Blocks',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryMaroon,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    _isLoadingBlocks
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: blockId,
                                  decoration: _inputDecoration('Select Block'),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: primaryMaroon,
                                  ),
                                  items: _blocks.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b['id'].toString(),
                                      child: Text(
                                        b['blockCode'] != null
                                            ? '${b['blockCode']} - ${b['description'] ?? 'Block'}'
                                            : 'Unnamed Block',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => blockId = val),
                                  validator: (val) {
                                    if (val == null || val.isEmpty)
                                      return 'Block is required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 56, // matching the default height of input
                                width: 56,
                                decoration: BoxDecoration(
                                  color: backgroundPink,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add, color: primaryMaroon),
                                  onPressed: _showManageBlocksBottomSheet,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    // Floor
                    _buildLabel('Floor'),
                    _buildTextField(
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(
                        Icons.layers,
                        color: Colors.black26,
                      ),
                      onSaved: (val) => floor = int.tryParse(val ?? '0'),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Floor is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area
                    _buildLabel('Area (sq. ft.)'),
                    _buildTextField(
                      hintText: '1200',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(
                        Icons.architecture,
                        color: Colors.black26,
                      ),
                      onSaved: (val) => area = double.tryParse(val ?? '0.0'),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Area is required';
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
                                child: const Icon(
                                  Icons.bar_chart,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Operational Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusOption(
                            title: 'Occupied',
                            subtitle: 'TENANT ACTIVE',
                            value: 'OCCUPIED',
                          ),
                          const SizedBox(height: 12),
                          _buildStatusOption(
                            title: 'Vacant',
                            subtitle: 'READY FOR LISTING',
                            value: 'VACANT',
                          ),
                          const SizedBox(height: 12),
                          _buildStatusOption(
                            title: 'Fixing',
                            subtitle: 'UNDER MAINTENANCE',
                            value: 'FIXING',
                          ),
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
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
                          ), // Placeholder
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
                            Text(
                              'PROPERTY LOCATION',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Central District Complex •\nPhase II',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Save Apartment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.verified, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            statusBoxFill, // matching the cancel button background
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryMaroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BulkCreateApartmentScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: primaryMaroon, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_add,
                            color: primaryMaroon,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bulk Import Apartments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryMaroon,
                            ),
                          ),
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

  // Helper Widget Builders
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
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

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    bool isSelected = status == value;
    return GestureDetector(
      onTap: () => setState(() => status = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryMaroon : Colors.transparent,
            width: 2,
          ),
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
