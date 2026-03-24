import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../services/cloudinary_service.dart';
import '../models/profile_model.dart';
import '../providers/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _relationshipController;
  late TextEditingController _identityCardController;

  String? _selectedGender;
  String? _selectedRelationship;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  bool _isLoading = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current profile data
    final names = widget.profile.fullName?.split(' ') ?? ['', ''];
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.emailFull);
    _phoneController = TextEditingController(text: widget.profile.phoneFull ?? '');
    _dobController = TextEditingController(text: widget.profile.dateOfBirth ?? '');
    _emergencyNameController = TextEditingController(
      text: widget.profile.emergencyContactName ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: widget.profile.emergencyContactPhone ?? '',
    );
    _identityCardController = TextEditingController(text: widget.profile.identityCard ?? '');
    _relationshipController = TextEditingController(text: 'Spouse');

    _selectedGender = widget.profile.gender;
    if (_selectedGender == null || _selectedGender!.trim().isEmpty || !['Male', 'Female', 'Other'].contains(_selectedGender)) {
      _selectedGender = null; // Default to null (shows hint) or can pick 'Other'
    }

    _selectedRelationship = widget.profile.emergencyContactRelationship;
    if (_selectedRelationship == null || _selectedRelationship!.trim().isEmpty || !['Spouse', 'Parent', 'Sibling', 'Friend', 'Other'].contains(_selectedRelationship)) {
      _selectedRelationship = 'Other'; // Better to default to a valid item
    }

    _emailNotifications = widget.profile.emailNotifications ?? true;
    _pushNotifications = widget.profile.pushNotifications ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _identityCardController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.profile.dateOfBirth != null
          ? DateTime.tryParse(widget.profile.dateOfBirth!) ?? DateTime(1990)
          : DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00BCD4)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00BCD4)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (widget.profile.avatarUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _uploadedImageUrl = '';  // Empty string to indicate removal
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageIfNeeded() async {
    if (_selectedImage == null) {
      return _uploadedImageUrl ?? widget.profile.avatarUrl;
    }

    try {
      final url = await _cloudinaryService.uploadImage(_selectedImage!);
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final themeProvider = context.read<ThemeProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Upload image if selected
      String? avatarUrl;
      if (_selectedImage != null || _uploadedImageUrl != null) {
        avatarUrl = await _uploadImageIfNeeded();
      }

      // Parse full name into firstname and lastname
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstname = nameParts.isNotEmpty ? nameParts.first : '';
      final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Prepare update data
      final updateData = {
        'firstname': firstname,
        'lastname': lastname,
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'gender': _selectedGender,
        'identityCard': _identityCardController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
        'emergencyContactRelationship': _selectedRelationship,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

      // Call API
      await _profileService.updateProfile(userId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 16),
              _buildPersonalInformation(),
              const SizedBox(height: 16),
              _buildEmergencyContact(),
              const SizedBox(height: 16),
              _buildPreferences(),
              const SizedBox(height: 16),
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2845D6),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.profile.avatarUrl != null && _uploadedImageUrl != ''
                        ? ClipOval(
                            child: Image.network(
                              widget.profile.avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  widget.profile.initials ?? 'JD',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            widget.profile.initials ?? 'JD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BCD4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showImageSourceDialog,
            child: const Text(
              'Change Photo',
              style: TextStyle(
                color: Color(0xFF00BCD4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.profile.avatarUrl != null || _selectedImage != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _uploadedImageUrl = '';
                });
              },
              child: const Text(
                'Remove Photo',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person, color: Color(0xFF00BCD4), size: 20),
              SizedBox(width: 8),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Full Name',
            controller: _fullNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Address',
            controller: _emailController,
            enabled: false,
            suffixWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixText: '+1 ',
            suffixWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Date of Birth',
            controller: _dobController,
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Gender',
            value: _selectedGender,
            items: ['Male', 'Female', 'Other'],
            onChanged: (value) => setState(() => _selectedGender = value),
            hintText: 'Select Gender',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Identity Card (CCCD/CMND)',
            controller: _identityCardController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your identity card number';
              }
              if (value.length != 9 && value.length != 12) {
                return 'Identity card must be 9 or 12 digits';
              }
              return null;
            },
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emergency, color: Color(0xFF00BCD4), size: 20),
              SizedBox(width: 8),
              Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Contact Name',
            controller: _emergencyNameController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone',
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            prefixText: '+1 ',
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Relationship',
            value: _selectedRelationship,
            items: ['Spouse', 'Parent', 'Sibling', 'Friend', 'Other'],
            onChanged: (value) => setState(() => _selectedRelationship = value),
            hintText: 'Select Relationship',
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings, color: Color(0xFF00BCD4), size: 20),
              SizedBox(width: 8),
              Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          _buildCheckboxTile(
            title: 'Email notifications',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value!),
          ),
          _buildCheckboxTile(
            title: 'Push notifications',
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    Widget? suffixWidget,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixText: prefixText,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: const Color(0xFF6B7280))
                : null,
            suffix: suffixWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: hintText != null ? Text(hintText) : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF374151),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF00BCD4),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
