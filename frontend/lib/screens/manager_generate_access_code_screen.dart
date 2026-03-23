import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_apartment_service.dart';
import '../services/api_block_service.dart';
import '../services/api_apartment_access_service.dart';

class ManagerGenerateAccessCodeScreen extends StatefulWidget {
  const ManagerGenerateAccessCodeScreen({super.key});

  @override
  State<ManagerGenerateAccessCodeScreen> createState() => _ManagerGenerateAccessCodeScreenState();
}

class _ManagerGenerateAccessCodeScreenState extends State<ManagerGenerateAccessCodeScreen> {
  final _apartmentService = ApiApartmentService();
  final _blockService = ApiBlockService();
  final _accessService = ApiApartmentAccessService();
  
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _blocks = [];
  List<dynamic> _apartments = [];
  int? _selectedBlockId;
  int? _selectedApartmentId;
  bool _isLoading = false;
  bool _isBlocksLoading = true;
  bool _isAptsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  Future<void> _loadBlocks() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final blocks = await _blockService.getBlocks(token: authProvider.accessToken!);
      setState(() {
        _blocks = blocks;
        _isBlocksLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blocks: $e')),
        );
      }
      setState(() => _isBlocksLoading = false);
    }
  }

  Future<void> _loadUnusedApartments(int blockId) async {
    setState(() {
      _isAptsLoading = true;
      _apartments = [];
      _selectedApartmentId = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // We use the paged API but with a large size or the dedicated getByUsed if we want ALL.
      // Since we updated the paged API to support 'used' and 'blockId', let's use it.
      final result = await _apartmentService.getApartments(
        token: authProvider.accessToken!,
        blockId: blockId,
        used: false,
        size: 100, // Load many at once for the dropdown
      );
      
      setState(() {
        _apartments = result['content'] ?? [];
        _isAptsLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apartments: $e')),
        );
      }
      setState(() => _isAptsLoading = false);
    }
  }

  Future<void> _generateAndSend() async {
    if (!_formKey.currentState!.validate() || _selectedApartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final code = await _accessService.generateCode(
        token: authProvider.accessToken!,
        apartmentId: _selectedApartmentId!,
        email: _emailController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Access code generated and sent to email.'),
                const SizedBox(height: 12),
                Text('Code: $code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF88304E);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Resident'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: _isBlocksLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Access Code',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select an available apartment and provide the resident\'s email to send an invitation code.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    
                    // Block Selection
                    const Text('Select Building/Block', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedBlockId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      hint: const Text('Choose a Block'),
                      items: _blocks.map((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text('${b['blockCode']} - ${b['description']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedBlockId = val);
                        if (val != null) _loadUnusedApartments(val);
                      },
                      validator: (val) => val == null ? 'Selection required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Apartment Selection
                    const Text('Select Apartment', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_isAptsLoading)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedApartmentId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        hint: Text(_selectedBlockId == null ? 'Select a block first' : 'Choose an Apartment'),
                        items: _apartments.map((a) {
                          return DropdownMenuItem<int>(
                            value: a['id'],
                            child: Text('${a['apartmentCode']} (Fl: ${a['floor']}, ${a['area']}m²)'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedApartmentId = val),
                        validator: (val) => val == null ? 'Selection required' : null,
                      ),
                    const SizedBox(height: 24),

                    // Email Field
                    const Text('Resident Email', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'e.g. resident@example.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email is required';
                        if (!val.contains('@')) return 'Invalid email format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateAndSend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Generate & Send Mail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
