import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';

class RequestDetailResponseScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailResponseScreen({super.key, required this.request});

  @override
  State<RequestDetailResponseScreen> createState() =>
      _RequestDetailResponseScreenState();
}

class _RequestDetailResponseScreenState
    extends State<RequestDetailResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  late RequestStatus _selectedStatus;
  late TextEditingController _responseController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status;
    _responseController = TextEditingController(text: widget.request.response);
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await context.read<RequestProvider>().updateRequestStatus(
        authProvider.accessToken!,
        widget.request.id,
        _selectedStatus,
        _responseController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respond to Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Request Information'),
              _buildInfoRow('ID', '#${widget.request.id}'),
              _buildInfoRow('Title', widget.request.title),
              _buildInfoRow('Resident', widget.request.userFullName),
              if (widget.request.userApartmentCode != null && widget.request.userApartmentCode != 'Unknown')
                _buildInfoRow('Apartment', widget.request.userApartmentCode!),
              _buildInfoRow(
                'Date',
                widget.request.createdAt.toString().substring(0, 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.request.description),
              const Divider(height: 32),

              _buildSectionTitle('Admin Response'),
              const SizedBox(height: 8),
              const Text('Update Status:'),
              DropdownButtonFormField<RequestStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (val) => setState(() => _selectedStatus = val!),
                items: RequestStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _responseController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Your Comment / Response',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: 'Enter internal response or reply to resident...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a response';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SUBMIT RESPONSE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
