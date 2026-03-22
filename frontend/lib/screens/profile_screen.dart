import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import '../routes/app_routes.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final profile = await _profileService.getProfile(userId);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Show menu options
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('No profile data'))
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildProfileCompletion(),
                            const SizedBox(height: 16),
                            _buildPersonalInformation(),
                            const SizedBox(height: 16),
                            _buildApartmentInformation(),
                            const SizedBox(height: 16),
                            _buildEmergencyContact(),
                            const SizedBox(height: 16),
                            _buildVehicleInformation(),
                            const SizedBox(height: 16),
                            _buildAccountSecurity(),
                            const SizedBox(height: 16),
                            _buildPreferences(),
                            const SizedBox(height: 16),
                            _buildEditButton(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
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
                child: _profile?.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _profile!.avatarUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        _profile?.initials ?? 'JD',
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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00BCD4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.fullName ?? 'Unknown User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                _profile?.emailMasked ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (_profile?.emailVerified == true) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 16, color: Color(0xFF00BCD4)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                _profile?.phoneMasked ?? 'Not provided',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (_profile?.phoneVerified == true) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 16, color: Color(0xFF00BCD4)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion() {
    final completion = _profile?.profileCompletion ?? 0;
    final items = _profile?.completionItems ?? [];

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '$completion%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00BCD4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items
                        .where((item) => item.completed)
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 16, color: Color(0xFF10B981)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MISSING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items
                        .where((item) => !item.completed)
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.radio_button_unchecked,
                                      size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person,
      iconColor: const Color(0xFF00BCD4),
      children: [
        _buildInfoRow('Account ID', _profile?.accountId ?? 'N/A'),
        _buildInfoRow('Identity Card', _profile?.identityCard ?? 'Not set'),
        _buildInfoRow('Date of Birth', _profile?.dateOfBirth ?? 'Not set'),
        _buildInfoRow('Gender', _profile?.gender ?? 'Not set'),
      ],
    );
  }

  Widget _buildApartmentInformation() {
    return _buildSection(
      title: 'Apartment Information',
      icon: Icons.apartment,
      iconColor: const Color(0xFF00BCD4),
      children: [
        _buildInfoRow('Apartment', _profile?.apartmentCode ?? 'N/A',
            badge: _profile?.ownershipStatus),
        _buildInfoRow('Block', _profile?.blockCode != null
            ? 'Tower ${_profile!.blockCode}'
            : 'N/A'),
        _buildInfoRow('Floor', _profile?.floor?.toString() ?? 'N/A'),
        _buildInfoRow('Type', _profile?.apartmentType ?? '3 Bedroom Suite'),
        _buildInfoRow('Move-in Date',
            _profile?.moveInDate ?? 'January 12, 2022'),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    return _buildSection(
      title: 'Emergency Contact',
      icon: Icons.emergency,
      iconColor: const Color(0xFF00BCD4),
      children: [
        if (_profile?.emergencyContactName != null ||
            _profile?.emergencyContactPhone != null)
          Column(
            children: [
              _buildInfoRow(
                _profile?.emergencyContactName ?? 'Emergency Contact',
                _profile?.emergencyContactPhone ?? 'Not set',
              ),
              if (_profile?.emergencyContactRelationship != null)
                _buildInfoRow(
                  'Relationship',
                  _profile!.emergencyContactRelationship!,
                ),
            ],
          )
        else
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Navigate to edit profile
              },
              icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
              label: const Text(
                'Add Contact Information',
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleInformation() {
    final vehicles = _profile?.vehicles ?? [];

    return _buildSection(
      title: 'Vehicle Information',
      icon: Icons.directions_car,
      iconColor: const Color(0xFF00BCD4),
      children: [
        if (vehicles.isNotEmpty)
          ...vehicles.map((vehicle) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Color(0xFF00BCD4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.type,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            vehicle.licensePlate,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: vehicle.status == 'ACTIVE'
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFF6B7280).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vehicle.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vehicle.status == 'ACTIVE'
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        else
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Navigate to add vehicle
              },
              icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
              label: const Text(
                'Add Vehicle',
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountSecurity() {
    return _buildSection(
      title: 'Account Security',
      icon: Icons.security,
      iconColor: const Color(0xFF00BCD4),
      children: [
        _buildInfoRow('Password', '••••••••', trailing: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.changePassword);
          },
          child: const Text(
            'Change',
            style: TextStyle(color: Color(0xFF00BCD4)),
          ),
        )),
        _buildInfoRow('Two-Factor Auth', 'Disabled', trailing: TextButton(
          onPressed: () {
            // Enable 2FA
          },
          child: const Text(
            'Enable',
            style: TextStyle(color: Color(0xFF00BCD4)),
          ),
        )),
        _buildInfoRow('Last Login', 'Oct 24, 2023 • 08:42 AM'),
      ],
    );
  }

  Widget _buildPreferences() {
    final notifications = <String>[];
    if (_profile?.emailNotifications == true) notifications.add('Email');
    if (_profile?.pushNotifications == true) notifications.add('Push');
    
    return _buildSection(
      title: 'Preferences',
      icon: Icons.settings,
      iconColor: const Color(0xFF00BCD4),
      children: [
        _buildInfoRow(
          'Notifications', 
          notifications.isEmpty ? 'Disabled' : notifications.join(', ')
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {String? badge, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_profile == null) return;
          
          // Navigate to edit screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(profile: _profile!),
            ),
          );

          // Reload profile if changes were saved
          if (result == true) {
            _loadProfile();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
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
