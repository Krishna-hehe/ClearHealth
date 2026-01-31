import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:convert';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/navigation.dart';
import '../../core/biometric_service.dart';
import 'mfa_setup_dialog.dart';
import 'data_export_service.dart';
import '../../widgets/glass_card.dart';
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
        final activeFactor = factors.all.firstWhere(
          (f) => f.status == FactorStatus.verified,
        );
        _mfaEnabled = true;
        _mfaFactorId = activeFactor.id;
      }
    } catch (e) {
      debugPrint('Error getting MFA factors: $e');
    }

    setState(() => _isLoading = false);
  }

  Map<String, dynamic> _getProfileData() {
    return {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'phone_number': _phoneController.text,
      'state': _stateController.text,
      'postal_code': _postalCodeController.text,
      'country': _countryController.text,
      'date_of_birth': _dob != 'Not set' ? _dob : null,
      'gender': _gender != 'Not set' ? _gender : null,
      'email_notifications': _emailNotifications,
      'result_reminders': _resultReminders,
    };
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(_getProfileData());
      ref.invalidate(userProfileProvider);
      ref.invalidate(userProfileStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await image.readAsBytes();
      final publicUrl = await ref
          .read(storageServiceProvider)
          .uploadProfilePhoto(bytes);

      if (publicUrl != null) {
        final profileData = _getProfileData();
        profileData['avatar_url'] = publicUrl;

        await ref.read(userRepositoryProvider).updateProfile(profileData);
        ref.invalidate(userProfileProvider);
        ref.invalidate(userProfileStreamProvider);
        setState(() => _avatarUrl = publicUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final profileData = _getProfileData();
    profileData['avatar_url'] = null;

    await ref.read(userRepositoryProvider).updateProfile(profileData);
    ref.invalidate(userProfileProvider);
    setState(() => _avatarUrl = null);
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(dataExportServiceProvider).exportUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete ALL your lab results, prescriptions, and health data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.red),
            ),
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
            const SnackBar(
              content: Text(
                'Your account and data have been permanently deleted.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
        await _signOut();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error closing account: $e'),
              backgroundColor: AppColors.danger,
            ),
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
        children: ['Male', 'Female', 'Other', 'Prefer not to say']
            .map(
              (g) => ListTile(
                title: Text(g),
                onTap: () => Navigator.pop(context, g),
              ),
            )
            .toList(),
      ),
    );
    if (gender != null) {
      setState(() => _gender = gender);
    }
  }

  Widget _buildEditableField(
    String label,
    String value, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            opacity: 0.03,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: AppColors.secondary),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          _buildPersonalInfoSection(),
          const SizedBox(height: 32),
          _buildNotificationsSection(),
          const SizedBox(height: 32),
          _buildPrivacySection(),
          const SizedBox(height: 32),
          _buildSupportSection(),
          const SizedBox(height: 64),
          Center(
            child: TextButton(
              onPressed: _signOut,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                foregroundColor: AppColors.secondary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          opacity: 0.1,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: const Icon(
              Icons.settings_suggest_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage your account & preferences',
              style: TextStyle(color: AppColors.secondary, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  // No changes to _buildPersonalInfoSection structure, but it uses the updated widgets.
  // We can just update the button styling and overall padding.
  Widget _buildPersonalInfoSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      opacity: 0.05,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildProfilePhotoRow(),
            const SizedBox(height: 32),
            _buildTextField('First Name', _firstNameController),
            const SizedBox(height: 20),
            _buildTextField('Last Name', _lastNameController),
            const SizedBox(height: 20),
            _buildReadOnlyField('Email Address', _email),
            const SizedBox(height: 20),
            _buildTextField('Phone Number', _phoneController),
            const SizedBox(height: 20),
            _buildEditableField(
              'Date of Birth',
              _dob,
              icon: Icons.calendar_today_rounded,
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            const Text(
              'Used to calculate age-appropriate normal ranges.',
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              'Gender',
              _gender,
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: _pickGender,
            ),
            const SizedBox(height: 8),
            const Text(
              'Used to determine gender-specific reference ranges.',
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('State / Province', _stateController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('Postal Code', _postalCodeController),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField('Country', _countryController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0, // Flat for glass look
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoRow() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ? NetworkImage(_avatarUrl!)
                : const NetworkImage('https://via.placeholder.com/150'),
            backgroundColor: const Color(0xFFF3F4F6),
            child: _isUploadingPhoto ? const CircularProgressIndicator() : null,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your profile picture.',
                style: TextStyle(color: AppColors.secondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _isUploadingPhoto ? null : _uploadPhoto,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upload New',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    TextButton(
                      onPressed: _removePhoto,
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          opacity: 0.03,
          padding: EdgeInsets.zero,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          opacity: 0.03,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary, // Muted for read-only
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: AppColors.secondary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.notifications_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            'Email Notifications',
            'Receive updates about new features and tips.',
            _emailNotifications,
            (val) => setState(() => _emailNotifications = val),
          ),
          const Divider(height: 48), // Increased spacing for cleaner look
          _buildSwitchTile(
            'Result Reminders',
            'Get reminded to check your latest lab results.',
            _resultReminders,
            (val) => setState(() => _resultReminders = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Privacy & Security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionRow(
            Icons.file_download_rounded,
            'Export Your Data',
            'Download all your medical data.',
            'Export',
            onPressed: _exportData,
          ),
          if (_canCheckBiometrics) ...[
            const Divider(height: 48),
            _buildSwitchTile(
              'Biometric Lock',
              'Require FaceID/Fingerprint to open app.',
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
              },
            ),
          ],
          const Divider(height: 48),
          _buildActionRow(
            Icons.delete_rounded,
            'Delete Account',
            'Permanently delete account and data.',
            'Delete',
            isDestructive: true,
            onPressed: _deleteAccount,
          ),
          const Divider(height: 48),
          _buildSwitchTile(
            'Two-Factor Auth (2FA)',
            'Use authenticator for extra security.',
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
                  await ref
                      .read(supabaseServiceProvider)
                      .removeMfaFactor(_mfaFactorId!);
                  _fetchProfile();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.help_center_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              Text(
                'Help & Support',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionRow(
            Icons.map_rounded,
            'Take a Tour',
            'Replay the onboarding walkthrough.',
            'Start Tour',
            onPressed: () {
              ref.read(showOnboardingProvider.notifier).state = true;
            },
          ),
          const Divider(height: 48),
          _buildActionRow(
            Icons.chat_bubble_rounded,
            'Contact Support',
            'Get help or report an issue.',
            'Contact',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    IconData icon,
    String title,
    String subtitle,
    String actionLabel, {
    bool isDestructive = false,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.red : AppColors.secondary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: isDestructive
                ? Colors.red.withValues(alpha: 0.05)
                : null,
          ),
          child: Text(
            actionLabel,
            style: TextStyle(
              color: isDestructive ? Colors.red : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
