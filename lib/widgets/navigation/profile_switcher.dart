import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import '../../core/navigation.dart';
import '../glass_card.dart';
import 'package:uuid/uuid.dart';

class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(userProfilesProvider);
    final selectedId = ref.watch(selectedProfileIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: 280,
      opacity: isDark ? 0.3 : 0.8,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SWITCH PROFILE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddProfileDialog(context, ref),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    color: AppColors.primaryBrand,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Add Profile',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            profilesAsync.when(
              data: (profiles) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      final isSelected =
                          profile.id == selectedId ||
                          (selectedId == null && index == 0);

                      return _ProfileItem(
                        profile: profile,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedProfileIdProvider.notifier).state =
                              profile.id;
                          Navigator.pop(context);
                        },
                        onDelete: profile.id == profile.userId
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                      'Are you sure you want to delete ${profile.firstName}? All lab results for this profile will be permanently removed.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
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
                              },
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navigationProvider.notifier).state =
                      NavItem.settings;
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Manage Profiles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final relationshipState = ValueNotifier<String>('Other');
    final formKey = GlobalKey<FormState>();

    final relationships = [
      {'name': 'Spouse', 'icon': Icons.favorite_outline},
      {'name': 'Child', 'icon': Icons.child_care_outlined},
      {'name': 'Parent', 'icon': Icons.supervisor_account_outlined},
      {'name': 'Other', 'icon': Icons.people_outline},
    ];

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
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Relationship',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBrand
                                  : AppColors.primaryBrand.withValues(
                                      alpha: 0.05,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBrand
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  rel['icon'] as IconData,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.primaryBrand,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rel['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Avatar Color',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final UserProfile profile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProfileItem({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = Color(int.parse(profile.avatarColor));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primaryBrand : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(8),
                  image: profile.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.avatarUrl == null
                    ? Center(
                        child: Text(
                          profile.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.fullName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: Colors.red.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      profile.relationship,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.primaryBrand,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
