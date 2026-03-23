import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_notification_service.dart';
import '../services/resident_service.dart';
import '../models/resident_model.dart';

class ManagerCreateNotificationScreen extends StatefulWidget {
  const ManagerCreateNotificationScreen({super.key});

  @override
  State<ManagerCreateNotificationScreen> createState() => _ManagerCreateNotificationScreenState();
}

class _ManagerCreateNotificationScreenState extends State<ManagerCreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _detailController = TextEditingController();
  
  final _notificationService = ApiNotificationService();
  final _residentService = ResidentService();

  bool _toAll = true;
  ResidentModel? _selectedResident;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_toAll && _selectedResident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resident')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _notificationService.sendNotification(
        token: authProvider.accessToken!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        detail: _detailController.text.trim().isEmpty ? null : _detailController.text.trim(),
        userId: _toAll ? null : _selectedResident!.userId,
        toAll: _toAll,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Create Notification'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Announcement',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
              ),
              const SizedBox(height: 8),
              const Text('Send a message to residents in the building.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Recipient Selection
              const Text('Recipient', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text('All Residents'),
                      value: true,
                      groupValue: _toAll,
                      activeColor: primary,
                      onChanged: (val) => setState(() => _toAll = val!),
                    ),
                    RadioListTile<bool>(
                      title: const Text('Specific Resident'),
                      value: false,
                      groupValue: _toAll,
                      activeColor: primary,
                      onChanged: (val) => setState(() => _toAll = val!),
                    ),
                  ],
                ),
              ),
              if (!_toAll) ...[
                const SizedBox(height: 16),
                const Text('Select Resident', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildResidentPicker(),
              ],
              const SizedBox(height: 24),

              // Title
              const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Maintenance Scheduled',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 24),

              // Short Content
              const Text('Message Summary', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Brief summary for push notification',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Summary is required' : null,
              ),
              const SizedBox(height: 24),

              // Full Detail
              const Text('Full Details (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Detailed information...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentPicker() {
    return Autocomplete<ResidentModel>(
      displayStringForOption: (option) => '${option.fullName} (${option.apartmentCode ?? "N/A"})',
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const Iterable<ResidentModel>.empty();
        
        setState(() => _isSearching = true);
        try {
          final response = await _residentService.getResidents(search: textEditingValue.text);
          setState(() => _isSearching = false);
          return response.residents;
        } catch (e) {
          setState(() => _isSearching = false);
          return const Iterable<ResidentModel>.empty();
        }
      },
      onSelected: (ResidentModel selection) {
        setState(() => _selectedResident = selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search by name or apartment...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
          ),
          onFieldSubmitted: (val) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ResidentModel option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.fullName),
                    subtitle: Text(option.apartmentCode ?? 'No apartment'),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
