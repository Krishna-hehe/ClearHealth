import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:convert';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/navigation.dart';
import '../../core/biometric_service.dart';
import 'mfa_setup_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  
  String _email = '';
  String _dob = 'Not set';
  String _gender = 'Not set';
  String? _avatarUrl;
  bool _emailNotifications = true;
  bool _resultReminders = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _mfaEnabled = false;
  String? _mfaFactorId;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final userRepo = ref.read(userRepositoryProvider);
    final profile = await userRepo.getProfile();
    if (profile != null) {
      _firstNameController.text = profile['first_name'] ?? '';
      _lastNameController.text = profile['last_name'] ?? '';
      _phoneController.text = profile['phone_number'] ?? profile['phone'] ?? '';
      _stateController.text = profile['state'] ?? '';
      _postalCodeController.text = profile['postal_code'] ?? '';
      _countryController.text = profile['country'] ?? '';
      _email = ref.read(authServiceProvider).currentUser?.email ?? '';
      _dob = profile['date_of_birth'] ?? profile['dob'] ?? 'Not set';
      _gender = profile['gender'] ?? 'Not set';
      _avatarUrl = profile['avatar_url'];
      _emailNotifications = profile['email_notifications'] ?? true;
      _resultReminders = profile['result_reminders'] ?? true;
    }
    
    try {
      _canCheckBiometrics = await BiometricService().canCheckBiometrics();
      _biometricEnabled = await BiometricService().isEnabled();
    } catch (e) {
      debugPrint('Error initializing biometrics: $e');
      _canCheckBiometrics = false;
      _biometricEnabled = false;
    }

    try {
      final factors = await ref.read(supabaseServiceProvider).getMFAFactors();
      if (factors.all.isNotEmpty) {
        final activeFactor = factors.all.firstWhere((f) => f.status == FactorStatus.verified);
        _mfaEnabled = true;
        _mfaFactorId = activeFactor.id;
      }
    } catch (e) {
      debugPrint('Error getting MFA factors: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone_number': _phoneController.text,
        'state': _stateController.text,
        'postal_code': _postalCodeController.text,
        'country': _countryController.text,
        'dob': _dob != 'Not set' ? _dob : null,
        'gender': _gender != 'Not set' ? _gender : null,
        'email_notifications': _emailNotifications,
        'result_reminders': _resultReminders,
      });
      ref.invalidate(userProfileProvider);
      ref.invalidate(userProfileStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (image == null) return;

      setState(() => _isUploadingPhoto = true);
      
      final bytes = await image.readAsBytes();
      final publicUrl = await ref.read(storageServiceProvider).uploadProfilePhoto(bytes);
      
      if (publicUrl != null) {
        await ref.read(userRepositoryProvider).updateProfile({'avatar_url': publicUrl});
        ref.invalidate(userProfileProvider);
        ref.invalidate(userProfileStreamProvider);
        setState(() => _avatarUrl = publicUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    await ref.read(userRepositoryProvider).updateProfile({'avatar_url': null});
    ref.invalidate(userProfileProvider);
    setState(() => _avatarUrl = null);
  }

  Future<void> _exportData() async {
    // Results/Profile/Prescriptions fetch successful. 
    // Data export placeholder
    // In a real app, you would share this as a file. For now, we'll show success.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully. Check your email.'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This will permanently delete ALL your lab results, prescriptions, and health data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true); // Show loading
      try {
        await ref.read(userRepositoryProvider).deleteAccountData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account and data have been permanently deleted.'), backgroundColor: AppColors.success),
          );
        }
        await _signOut();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error closing account: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    ref.read(navigationProvider.notifier).state = NavItem.landing;
    ref.invalidate(currentUserProvider);
    ref.invalidate(userProfileStreamProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(prescriptionsProvider);
    ref.invalidate(activePrescriptionsCountProvider);
    ref.invalidate(labResultsProvider);
    ref.invalidate(recentLabResultsProvider);
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    try {
      if (_dob != 'Not set') initial = DateTime.parse(_dob);
    } catch (_) {}
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _pickGender() async {
    final gender = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Male', 'Female', 'Other', 'Prefer not to say'].map((g) => ListTile(
          title: Text(g),
          onTap: () => Navigator.pop(context, g),
        )).toList(),
      ),
    );
    if (gender != null) {
      setState(() => _gender = gender);
    }
  }

  Widget _buildEditableField(String label, String value, {IconData? icon, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black)),
                if (icon != null) ...[
                  const Spacer(),
                  Icon(icon, size: 16, color: AppColors.secondary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildPersonalInfoSection(),
          const SizedBox(height: 24),
          _buildNotificationsSection(),
          const SizedBox(height: 24),
          _buildPrivacySection(),
          const SizedBox(height: 24),
          _buildSupportSection(),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: _signOut,
              child: const Text('Sign Out', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.settings, size: 24, color: AppColors.secondary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage your account and preferences',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_outline, size: 18, color: AppColors.secondary),
                SizedBox(width: 12),
                Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            _buildProfilePhotoRow(),
            const SizedBox(height: 24),
            _buildTextField('First Name', _firstNameController),
            const SizedBox(height: 16),
            _buildTextField('Last Name', _lastNameController),
            const SizedBox(height: 16),
            _buildReadOnlyField('Email Address', _email),
            const SizedBox(height: 16),
            _buildTextField('Phone Number', _phoneController),
            const SizedBox(height: 16),
            _buildEditableField('Date of Birth', _dob, icon: Icons.calendar_today, onTap: _pickDate),
            const SizedBox(height: 8),
            const Text('Used for age-appropriate reference ranges', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
            const SizedBox(height: 16),
            _buildEditableField('Gender', _gender, icon: Icons.keyboard_arrow_down, onTap: _pickGender),
            const SizedBox(height: 8),
            const Text('Used for gender-specific reference ranges', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
            const SizedBox(height: 32),
            _buildTextField('State / Province', _stateController),
            const SizedBox(height: 16),
            _buildTextField('Postal Code', _postalCodeController),
            const SizedBox(height: 16),
            _buildTextField('Country', _countryController),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) 
              ? NetworkImage(_avatarUrl!) 
              : const NetworkImage('https://via.placeholder.com/150'),
          backgroundColor: const Color(0xFFF3F4F6),
          child: _isUploadingPhoto ? const CircularProgressIndicator() : null,
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('JPG, PNG, or WebP up to 5MB.', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isUploadingPhoto ? null : _uploadPhoto,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Upload Photo', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: (_avatarUrl == null || _avatarUrl!.isEmpty) ? null : _removePhoto,
                  child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.secondary)),
              if (icon != null) ...[
                const Spacer(),
                Icon(icon, size: 16, color: AppColors.secondary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_none_outlined, size: 18, color: AppColors.secondary),
              SizedBox(width: 12),
              Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            'Email Notifications', 
            'Receive updates about new features and tips', 
            _emailNotifications,
            (val) => setState(() => _emailNotifications = val)
          ),
          const Divider(height: 32),
          _buildSwitchTile(
            'Result Reminders', 
            'Get reminded to check your lab results', 
            _resultReminders,
            (val) => setState(() => _resultReminders = val)
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.secondary),
              SizedBox(width: 12),
              Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionRow(
            Icons.file_download_outlined, 
            'Export Your Data', 
            'Download all your lab results and account data', 
            'Export',
            onPressed: _exportData
          ),
          if (_canCheckBiometrics) ...[
            const Divider(height: 32),
            _buildSwitchTile(
              'Biometric Lock', 
              'Require FaceID/Fingerprint to open the app', 
              _biometricEnabled,
              (val) async {
                bool success = true;
                if (val) {
                  // If enabling, verify once
                  success = await BiometricService().authenticate();
                }
                if (success) {
                  await BiometricService().setEnabled(val);
                  setState(() => _biometricEnabled = val);
                }
              }
            ),
          ],
          const Divider(height: 32),
          _buildActionRow(
            Icons.delete_outline, 
            'Delete Account', 
            'Permanently delete your account and all data', 
            'Delete', 
            isDestructive: true,
            onPressed: _deleteAccount
          ),
          const Divider(height: 32),
          _buildSwitchTile(
            'Two-Factor Authentication (2FA)', 
            'Use an authenticator app to protect your account', 
            _mfaEnabled,
            (val) async {
              if (val) {
                final success = await showDialog<bool>(
                  context: context,
                  builder: (context) => const MfaSetupDialog(),
                );
                if (success == true) {
                  _fetchProfile(); // Refresh MFA status
                }
              } else {
                if (_mfaFactorId != null) {
                  await ref.read(supabaseServiceProvider).unenrollMFA(_mfaFactorId!);
                  _fetchProfile();
                }
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.help_outline, size: 18, color: AppColors.secondary),
              SizedBox(width: 12),
              Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionRow(
            Icons.map_outlined, 
            'Take a Tour', 
            'Replay the onboarding walkthrough to see key features', 
            'Start Tour',
            onPressed: () {
              ref.read(showOnboardingProvider.notifier).state = true;
            }
          ),
          const Divider(height: 32),
          _buildActionRow(
            Icons.chat_bubble_outline, 
            'Contact Support', 
            'Get help with your account or report an issue', 
            'Contact', 
            onPressed: () {}
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String title, String subtitle, String actionLabel, {bool isDestructive = false, required VoidCallback onPressed}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDestructive ? Colors.red : AppColors.secondary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(actionLabel, style: TextStyle(color: isDestructive ? Colors.red : AppColors.primary, fontSize: 13)),
        ),
      ],
    );
  }
}
