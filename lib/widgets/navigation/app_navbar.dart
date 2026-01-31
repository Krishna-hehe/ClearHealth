import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/navigation.dart';
import '../../../core/providers.dart';
import '../../../features/settings/family_profiles_page.dart';
import 'profile_switcher.dart';

class AppNavbar extends ConsumerWidget {
  final String email;

  const AppNavbar({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TextField(
                onChanged: (text) {
                  ref.read(searchQueryProvider.notifier).state = text;
                },
                decoration: const InputDecoration(
                  hintText: 'Search results, tests...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.secondary,
            ),
            onPressed: () => ref.read(navigationProvider.notifier).state =
                NavItem.notifications,
          ),
          IconButton(
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: AppColors.secondary,
            ),
            onPressed: () {
              final newMode = ref.read(themeProvider) == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeProvider.notifier).state = newMode;
            },
          ),
          const SizedBox(width: 8),
          _buildUserMenu(context, ref),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(selectedProfileProvider);
    final profile = profileAsync.value;
    final avatarUrl = profile?.avatarUrl;
    final avatarColor = profile != null
        ? Color(int.parse(profile.avatarColor))
        : const Color(0xFFF3F4F6);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            backgroundColor: avatarColor,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    (profile?.firstName[0] ?? 'L').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.secondary,
          ),
        ],
      ),
      onSelected: (value) async {
        if (value == 'switch_profile') {
          showDialog(
            context: context,
            barrierColor: Colors.black26,
            builder: (context) => const Center(child: ProfileSwitcher()),
          );
        } else if (value == 'settings') {
          ref.read(navigationProvider.notifier).state = NavItem.settings;
        } else if (value == 'family_profiles') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FamilyProfilesPage()),
          );
        } else if (value == 'signout') {
          await ref.read(authServiceProvider).signOut();
          ref.read(navigationProvider.notifier).state = NavItem.landing;
          ref.invalidate(currentUserProvider);
          ref.invalidate(userProfileStreamProvider);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.isEmpty ? 'user@example.com' : email,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Free Plan',
                style: TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'switch_profile',
          child: Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: AppColors.primaryBrand,
              ),
              SizedBox(width: 12),
              Text(
                'Switch Profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBrand,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 16),
              SizedBox(width: 12),
              Text('Settings', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'family_profiles',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 16),
              SizedBox(width: 12),
              Text('Family Profiles', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'subscription',
          child: Row(
            children: [
              Icon(Icons.credit_card_outlined, size: 16),
              SizedBox(width: 12),
              Text('Subscription', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
