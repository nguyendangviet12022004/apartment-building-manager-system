import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_request_service.dart';
import '../providers/auth_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiRequestService _apiService = ApiRequestService();

  String? _selectedIssueType;
  final TextEditingController _titleController = TextEditingController();
  String _selectedLocation = 'In apartment';
  DateTime? _selectedTime;
  String _selectedPriority = 'Low';
  final TextEditingController _descController = TextEditingController();
  final List<File> _files = [];
  bool _isLoading = false;

  final List<String> _issueTypes = [
    'Electrical',
    'Plumbing',
    'HVAC',
    'Maintenance',
    'Other',
  ];

  final List<String> _locations = [
    'In apartment',
    'Lobby',
    'Hallway',
    'Parking',
    'Other',
  ];

  final List<String> _priorities = ['Emergency', 'High', 'Medium', 'Low'];

  Future<void> _pickImage() async {
    if (_files.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 5 files allowed')));
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _files.add(File(pickedFile.path));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _selectedTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String priorityMapping = _selectedPriority.toUpperCase();
      if (priorityMapping == 'EMERGENCY') {
        priorityMapping =
            'HIGH'; // Fallback if backend doesn't support EMERGENCY
      }

      final token = context.read<AuthProvider>().accessToken;
      if (token == null) throw Exception("User is not authenticated");

      await _apiService.submitResidentRequest(
        token: token,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        issueType: _selectedIssueType!,
        priority: priorityMapping,
        location: _selectedLocation,
        occurrenceTime: _selectedTime?.toIso8601String(),
        files: _files,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Request Submitted', textAlign: TextAlign.center),
            ],
          ),
          content: const Text(
            'Your request has been successfully submitted.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                  Navigator.of(
                    context,
                  ).pop(true); // return true to refresh list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
      // } catch (e) {
      //   setState(() => _isLoading = false);
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Failed to submit request')),
      //   );
      // }
    } catch (e) {
      print(
        "Lỗi cụ thể: $e",
      ); // In ra console để xem server trả về 400, 404 hay 500
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
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
          'New Report',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report an Issue',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please provide details about the issue so our maintenance team can assist you better.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Issue Type *'),
                    _buildDropdownField(
                      value: _selectedIssueType,
                      hint: 'Select category',
                      options: _issueTypes,
                      onChanged: (v) => setState(() => _selectedIssueType = v),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Title *'),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Brief summary of the issue',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'This field is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Location'),
                    _buildDropdownField(
                      value: _selectedLocation,
                      hint: 'Select location',
                      options: _locations,
                      onChanged: (v) => setState(() => _selectedLocation = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Occurrence Time'),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Tap to select time'
                              : '${_selectedTime!.day}/${_selectedTime!.month}/${_selectedTime!.year} ${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _selectedTime == null
                                ? Colors.grey.shade500
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Priority Level'),
                    Wrap(
                      spacing: 8,
                      children: _priorities.map((p) {
                        final isSelected = _selectedPriority == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedPriority = p);
                            }
                          },
                          selectedColor: const Color(0xFF0D47A1),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Color(0xFF1E40AF)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Our team typically responds to High priority issues within 2 hours, and others within 24 hours.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Detailed Description *'),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Provide as much detail as possible...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'This field is required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Photos/Videos'),
                        Text(
                          '${_files.length}/5',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._files.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(entry.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeFile(entry.key),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        if (_files.length < 5)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 48), // Bottom padding
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Submit Report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: Text(hint),
      items: options
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
