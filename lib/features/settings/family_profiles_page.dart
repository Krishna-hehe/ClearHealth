import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'package:uuid/uuid.dart';

class FamilyProfilesPage extends ConsumerStatefulWidget {
  const FamilyProfilesPage({super.key});

  @override
  ConsumerState<FamilyProfilesPage> createState() => _FamilyProfilesPageState();
}

class _FamilyProfilesPageState extends ConsumerState<FamilyProfilesPage> {
  Future<void> _updateProfilePhoto(UserProfile profile) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final publicUrl = await ref
          .read(userRepositoryProvider)
          .uploadProfilePhoto(profile.id, bytes);

      if (publicUrl != null) {
        ref.invalidate(userProfilesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddProfileDialog() {
    final nameController = TextEditingController();
    final relationshipState = ValueNotifier<String>('Child');
    final formKey = GlobalKey<FormState>();

    final relationships = [
      {'name': 'Spouse', 'icon': Icons.favorite_outline},
      {'name': 'Child', 'icon': Icons.child_care_outlined},
      {'name': 'Parent', 'icon': Icons.supervisor_account_outlined},
      {'name': 'Other', 'icon': Icons.people_outline},
    ];

    // Premium color palette (HSL-based)
    final colors = [
      '0xFF3B82F6', // Blue 500
      '0xFF10B981', // Emerald 500
      '0xFFF59E0B', // Amber 500
      '0xFFEF4444', // Red 500
      '0xFF8B5CF6', // Violet 500
      '0xFFEC4899', // Pink 500
      '0xFF06B6D4', // Cyan 500
    ];
    String selectedColor = colors[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Family Member'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        hintText: 'e.g. Sarah',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Relationship',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: relationships.map((rel) {
                        final isSelected =
                            relationshipState.value == rel['name'];
                        return GestureDetector(
                          onTap: () {
                            relationshipState.value = rel['name'] as String;
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  rel['icon'] as IconData,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rel['name'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.secondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Avatar Color',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Color(int.parse(c))
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(int.parse(c)),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final newProfile = UserProfile(
                id: const Uuid().v4(),
                userId: '',
                firstName: nameController.text,
                relationship: relationshipState.value,
                avatarColor: selectedColor,
              );

              try {
                await ref
                    .read(userRepositoryProvider)
                    .createProfile(newProfile);
                ref.invalidate(userProfilesProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareDialog(UserProfile profile) async {
    final durationState = ValueNotifier<Duration>(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share ${profile.firstName}\'s Health Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a secure, temporary link for a doctor or specialist. They will see a read-only view of lab results.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Expires in:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<Duration>(
              valueListenable: durationState,
              builder: (context, duration, _) {
                return DropdownButton<Duration>(
                  value: duration,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: Duration(hours: 1),
                      child: Text('1 Hour'),
                    ),
                    DropdownMenuItem(
                      value: Duration(days: 1),
                      child: Text('24 Hours'),
                    ),
                    DropdownMenuItem(
                      value: Duration(days: 7),
                      child: Text('7 Days'),
                    ),
                    DropdownMenuItem(
                      value: Duration(days: 30),
                      child: Text('30 Days'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) durationState.value = val;
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Generate Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close config dialog
              await _generateAndShowLink(profile.id, durationState.value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShowLink(String profileId, Duration duration) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final token = await ref
          .read(supabaseServiceProvider)
          .createShareLink(profileId: profileId, duration: duration);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Construct URL (Assuming Hash Strategy for Flutter Web)
      final baseUrl = Uri.base.origin; // e.g., http://localhost:PORT
      final link = '$baseUrl/#/doctor_view?token=$token';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Link Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              SelectableText(
                link,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Copy this link and send it to your doctor.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(userProfilesProvider);
    final selectedId = ref.watch(selectedProfileIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Profiles')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfileDialog,
        child: const Icon(Icons.add),
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No profiles found. Create one now!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddProfileDialog,
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isSelected =
                  profile.id == selectedId ||
                  (selectedId == null && index == 0); // Logic matches provider

              return Card(
                elevation: isSelected ? 4 : 1,
                shape: isSelected
                    ? RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () => _updateProfilePhoto(profile),
                    child: Hero(
                      tag: 'profile_${profile.id}',
                      child: CircleAvatar(
                        backgroundColor: Color(int.parse(profile.avatarColor)),
                        backgroundImage: profile.avatarUrl != null
                            ? CachedNetworkImageProvider(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.firstName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                    ),
                  ),
                  title: Text(
                    profile.fullName.isEmpty ? 'Unknown' : profile.fullName,
                  ),
                  subtitle: Text(profile.relationship),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Chip(
                          label: Text('Active'),
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.primary),
                        tooltip: 'Share with Doctor',
                        onPressed: () => _showShareDialog(profile),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          if (!isSelected)
                            const PopupMenuItem(
                              value: 'select',
                              child: Text('Switch to this Profile'),
                            ),
                          if (profile.id != profile.userId)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                        onSelected: (value) async {
                          if (value == 'select') {
                            ref.read(selectedProfileIdProvider.notifier).state =
                                profile.id;
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: Text(
                                  'Are you sure you want to delete ${profile.firstName}? All lab results will be deleted.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref
                                  .read(userRepositoryProvider)
                                  .deleteProfile(profile.id);
                              ref.invalidate(userProfilesProvider);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(selectedProfileIdProvider.notifier).state =
                        profile.id;
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
