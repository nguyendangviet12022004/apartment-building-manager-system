import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_apartment_service.dart';

class EditApartmentScreen extends StatefulWidget {
  final Map<String, dynamic> apartmentDetail;

  const EditApartmentScreen({super.key, required this.apartmentDetail});

  @override
  State<EditApartmentScreen> createState() => _EditApartmentScreenState();
}

class _EditApartmentScreenState extends State<EditApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiApartmentService _apiService = ApiApartmentService();
  
  bool _isLoading = false;
  String _errorMessage = '';

  late TextEditingController _codeController;
  late TextEditingController _blockIdController;
  late TextEditingController _floorController;
  late TextEditingController _areaController;
  
  String _selectedStatus = 'VACANT';
  
  final List<String> _statusOptions = ['VACANT', 'OCCUPIED', 'FIXING'];

  String _normalizeStatus(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return 'VACANT';
    final upper = rawStatus.toUpperCase().trim();
    if (upper == 'AVAILABLE' || upper == 'VACANT') return 'VACANT';
    if (upper == 'OCCUPIED') return 'OCCUPIED';
    if (upper == 'FIXING' || upper == 'MAINTENANCE') return 'FIXING';
    return upper;
  }

  String _getDisplayLabel(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'OCCUPIED': return 'Occupied';
      case 'VACANT': return 'Vacant';
      case 'FIXING': return 'Fixing';
      default: return normalizedStatus;
    }
  }

  final Color _primaryMaroon = const Color(0xFF7A2A46);
  final Color _backgroundPink = const Color(0xFFFDF8F9);
  final Color _inputBackground = const Color(0xFFF2DEDF).withOpacity(0.5);

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.apartmentDetail['apartmentCode']?.toString() ?? '');
    _blockIdController = TextEditingController(text: widget.apartmentDetail['blockId']?.toString() ?? '');
    _floorController = TextEditingController(text: widget.apartmentDetail['floor']?.toString() ?? '');
    _areaController = TextEditingController(text: widget.apartmentDetail['area']?.toString() ?? '');
    _selectedStatus = _normalizeStatus(widget.apartmentDetail['status']?.toString());
    if (!_statusOptions.contains(_selectedStatus)) {
      _statusOptions.add(_selectedStatus);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _blockIdController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _updateApartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken ?? '';
      
      await _apiService.updateApartment(
        id: widget.apartmentDetail['id'],
        token: token,
        apartmentCode: _codeController.text.trim(),
        floor: int.parse(_floorController.text.trim()),
        area: double.parse(_areaController.text.trim()),
        status: _selectedStatus,
        blockId: int.parse(_blockIdController.text.trim()),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apartment updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Top summary placeholders matching UI design
    final bool isOccupied = _selectedStatus == 'OCCUPIED';

    return Scaffold(
      backgroundColor: _backgroundPink,
      appBar: AppBar(
        backgroundColor: _backgroundPink,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Update Apartment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isOccupied ? const Color(0xFFFFEAEA) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.red.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('OCCUPANCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                isOccupied ? 'Occupied' : 'Vacant',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _primaryMaroon),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAE8EB).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.red.withOpacity(0.1)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LAST CHECK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                              SizedBox(height: 4),
                              Text(
                                'Oct 12',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _primaryMaroon.withOpacity(0.1)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Apartment Code'),
                          _buildTextField(
                            controller: _codeController,
                            hint: 'XXX-XXXX-XXX',
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Code is required';
                              if (!RegExp(r'^[A-Z0-9]{3}-[0-9]{4}-[A-Z0-9]{3}$').hasMatch(val)) {
                                return 'Format must be XXX-XXXX-XXX';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Block ID'),
                          _buildTextField(
                            controller: _blockIdController,
                            hint: 'e.g. 1',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Block ID is required';
                              if (int.tryParse(val) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Floor Level'),
                          _buildTextField(
                            controller: _floorController,
                            hint: 'e.g. 4',
                            suffixText: 'th Floor',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Floor is required';
                              if (int.tryParse(val) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Total Area'),
                          _buildTextField(
                            controller: _areaController,
                            hint: 'e.g. 1250',
                            suffixText: 'm²',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Area is required';
                              if (double.tryParse(val) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('Apartment Status'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: _inputBackground,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                ),
                                borderRadius: BorderRadius.circular(24),
                                dropdownColor: Colors.white,
                                items: _statusOptions.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 20.0),
                                      child: Text(
                                        _getDisplayLabel(status),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedStatus = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _updateApartment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryMaroon,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Update Details',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dummy remove unit button matching design
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEAEA),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: _primaryMaroon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Remove Unit',
                          style: TextStyle(color: _primaryMaroon, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: _inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixText != null
            ? Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      suffixText,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ],
                ),
              )
            : null,
      ),
      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }
}
