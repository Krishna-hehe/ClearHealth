import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme.dart';
import '../core/navigation.dart';
import '../features/home/dashboard_page.dart';
import '../features/lab_results/results_list_page.dart';
import '../features/lab_results/result_detail_page.dart';
import '../features/lab_results/result_expanded_page.dart';
import '../features/trends/trends_page.dart';
import '../features/conditions/conditions_page.dart';
import '../features/prescriptions/prescriptions_page.dart';
import '../features/settings/settings_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/chat/health_chat_page.dart';
import '../features/auth/login_page.dart';
import '../features/share/share_results_page.dart';
import '../core/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_overlay.dart';
import 'offline_banner.dart';
import '../features/lab_results/comparison_page.dart';
import '../features/optimization/recipes_page.dart';
import '../features/community/health_circles_page.dart';
import '../features/home/landing_page.dart';
import '../features/admin/admin_page.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  String _email = '';
  bool _isUploading = false;
  // No _uploadStatus

  @override
  void initState() {
    super.initState();
    // We can use ref.read here as it's safe in initState or after
    // But since SupabaseService is provided, we should probably read it via ref
    // However, ref.read in initState is restricted for providers. 
    // Actually, ref.read(provider) is valid in initState if we don't watch. 
    // A better approach for initState dependencies is to use `ref.read` in a post-frame callback OR just use `ref` in build or use `ConsumerState` lifecycle.
    // Let's use ref.read inside the methods or setup a local variable if needed.
    // For initState, we can just defer to _checkOnboarding which is async.
    
    // _email = ref.read(supabaseServiceProvider).currentUser?.email ?? ''; // This is risky in initState if provider depends on something dynamic, but here it's likely fine. 
    // Safe way:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (mounted && user != null) {
        setState(() {
          _email = user.email ?? '';
        });
      }
    });

    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('has_seen_tour') ?? false;
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (!hasSeenTour && currentUser != null) {
      ref.read(showOnboardingProvider.notifier).state = true;
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tour', true);
    ref.read(showOnboardingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1100;
    // Data export placeholder
    final currentNav = ref.watch(navigationProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Auth Guard
    if (currentUser == null && currentNav != NavItem.landing && currentNav != NavItem.auth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).state = NavItem.landing;
      });
    } else if (currentUser != null && currentNav == NavItem.auth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).state = NavItem.dashboard;
      });
    }

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Stack(
      children: [
        // Premium Background (Mesh Gradient effect)
        Container(
          decoration: BoxDecoration(
            gradient: isDark 
              ? const RadialGradient(
                  center: Alignment(-0.6, -0.6),
                  radius: 2.0,
                  colors: [
                    Color(0xFF1F2937), // Dark Blue-Grey hint
                    Color(0xFF111827), // Cooler Dark
                    Color(0xFF030712), // Deepest Black
                  ],
                  stops: [0.0, 0.4, 1.0],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
               const OfflineBanner(),
               if (currentNav == NavItem.auth) 
                const Expanded(child: LoginPage())
              else ...[
              if (currentNav == NavItem.landing)
                _buildLandingNavbar()
              else if (isDesktop)
                // Sidebar logic for non-landing pages handled below in Row
                SizedBox.shrink(),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop && currentNav != NavItem.landing) _buildSidebar(currentNav),
                    Expanded(
                      child: Column(
                        children: [
                          if (_isUploading)
                            LinearProgressIndicator(
                              backgroundColor: AppColors.primary.withAlpha(51),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          if (currentNav != NavItem.landing) _buildNavbar(),
                          Expanded(
                            child: Padding(
                              padding: currentNav == NavItem.landing ? EdgeInsets.zero : const EdgeInsets.all(24.0),
                              child: _getPageContent(currentNav),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ],
          ),
        ),
        if (ref.watch(showOnboardingProvider))
          OnboardingOverlay(onComplete: _completeOnboarding),
      ],
    );
  }

  Widget _buildLandingNavbar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBF7),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'LabSense',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                   ref.read(isSignUpModeProvider.notifier).state = false;
                   ref.read(navigationProvider.notifier).state = NavItem.auth;
                },
                child: const Text('Log in', style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                   ref.read(isSignUpModeProvider.notifier).state = true;
                   ref.read(navigationProvider.notifier).state = NavItem.auth;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getPageContent(NavItem item) {
    switch (item) {
      case NavItem.landing:
        return const LandingPage();
      case NavItem.dashboard:
        return const DashboardPage();
      case NavItem.labResults:
        return const ResultsListPage();
      case NavItem.trends:
        return const TrendsPage();
      case NavItem.conditions:
        return const ConditionsPage();
      case NavItem.prescriptions:
        return const PrescriptionsPage();
      case NavItem.settings:
        return const SettingsPage();
      case NavItem.notifications:
        return const NotificationsPage();
      case NavItem.resultDetail:
        return const ResultDetailPage();
      case NavItem.resultExpanded:
        return const ResultExpandedPage();
      case NavItem.healthChat:
        return const HealthChatPage();
      case NavItem.shareResults:
        return const ShareResultsPage();
      case NavItem.comparison:
        return const ComparisonPage();
      case NavItem.healthOptimization:
        return const RecipesPage();
      case NavItem.healthCircles:
        return const HealthCirclesPage();
      case NavItem.admin:
        return const AdminPage();
      default:
        return Center(child: Text('${item.name} Content - Coming Soon'));
    }
  }

  Widget _buildSidebar(NavItem currentNav) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'LabSense',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _buildUserCard(ref),
          const SizedBox(height: 24),
          _buildUploadButton(),
          const SizedBox(height: 24),
          _buildSidebarItem(NavItem.dashboard, FontAwesomeIcons.house, 'Dashboard', currentNav),
          _buildSidebarItem(NavItem.labResults, FontAwesomeIcons.vial, 'Lab Results', currentNav),
          _buildSidebarItem(NavItem.trends, FontAwesomeIcons.chartLine, 'Trends', currentNav),
          _buildSidebarItem(NavItem.conditions, FontAwesomeIcons.heartPulse, 'Conditions', currentNav),
          _buildSidebarItem(NavItem.prescriptions, FontAwesomeIcons.pills, 'Prescriptions', currentNav),
          _buildSidebarItem(NavItem.healthChat, FontAwesomeIcons.robot, 'Ask LabSense', currentNav),
          _buildSidebarItem(NavItem.shareResults, FontAwesomeIcons.shareFromSquare, 'Share Results', currentNav),
          _buildSidebarItem(NavItem.healthOptimization, FontAwesomeIcons.leaf, 'Optimization', currentNav),
          _buildSidebarItem(NavItem.healthCircles, FontAwesomeIcons.users, 'Health Circles', currentNav),
          const Spacer(),
          _buildSidebarItem(NavItem.settings, FontAwesomeIcons.gear, 'Settings', currentNav),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserCard(WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    
    return profileAsync.when(
      data: (profile) {
        final name = profile != null 
            ? '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim()
            : 'LabSense User';
        final avatarUrl = profile?['avatar_url'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : const NetworkImage('https://via.placeholder.com/150'),
                backgroundColor: const Color(0xFFF3F4F6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'LabSense User' : name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Personal',
                      style: TextStyle(color: AppColors.secondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.secondary),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        icon: const Icon(FontAwesomeIcons.upload, size: 14),
        label: const Text('Upload Document'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isUploading ? null : _handleUpload,
      ),
    );
  }

  Future<void> _handleUpload() async {
    try {
      /*
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
        // _uploadStatus = 'Uploading document...';
      });

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes');

      final fileName = file.name;
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';
      */
      return; // Return early
      // The rest is already commented or follows
      
      /*
      // Compress if image
      Uint8List? finalBytes = bytes;
      
      if (finalBytes == null) throw Exception('File processing failed');

      // 1. Upload to Storage
      final storagePath = await ref.read(storageServiceProvider).uploadLabReport(finalBytes, fileName);
      if (storagePath == null) throw Exception('Failed to upload to storage');

      setState(() {}); // Removed _uploadStatus

      // 2. AI Parse (Gemini Vision)
      final parsedData = await ref.read(aiServiceProvider).parseLabReport(finalBytes, mimeType);
      
      if (!mounted) return;
      // 3. Review Step
      final confirmedData = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _OcrReviewDialog(initialData: parsedData!),
      );

      if (confirmedData == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // 4. Save to Database
      final Map<String, dynamic> finalData = {
        ...confirmedData,
        'storage_path': storagePath,
      };
      await ref.read(labRepositoryProvider).createLabResult(finalData);

      // 5. Refresh data
      ref.invalidate(labResultsProvider);
      ref.invalidate(recentLabResultsProvider);
      ref.invalidate(dashboardAiInsightProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lab report added successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        String errorMessage = e.toString();
        // Extract message from Exception wrapper if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        if (errorMessage.contains('lab-reports')) {
          errorMessage = 'Storage bucket missing or inaccessible. Please contact support.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $errorMessage'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      */
    } catch (e) {}
  }

  Widget _buildSidebarItem(NavItem item, IconData icon, String title, NavItem currentNav) {
    bool isSelected = item == currentNav || 
                     (item == NavItem.labResults && (currentNav == NavItem.resultDetail || currentNav == NavItem.resultExpanded));
    
    return InkWell(
      onTap: () => ref.read(navigationProvider.notifier).state = item,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: (text) {
                  ref.read(searchQueryProvider.notifier).state = text;
                },
                decoration: InputDecoration(
                  hintText: 'Search results, tests...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // _buildUpgradeBadge() removed

          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.secondary),
            onPressed: () => ref.read(navigationProvider.notifier).state = NavItem.notifications,
          ),
          IconButton(
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.secondary,
            ),
            onPressed: () {
              final newMode = ref.read(themeProvider) == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeProvider.notifier).state = newMode;
            },
          ),
          const SizedBox(width: 8),
          _buildUserMenu(ref),
        ],
      ),
    );
  }

  Widget _buildUserMenu(WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final avatarUrl = profileAsync.value?['avatar_url'];

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : const NetworkImage('https://via.placeholder.com/150'),
            backgroundColor: const Color(0xFFF3F4F6),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.secondary),
        ],
      ),
            onSelected: (value) async {
              if (value == 'settings') {
                ref.read(navigationProvider.notifier).state = NavItem.settings;
              } else if (value == 'signout') {
                await ref.read(authServiceProvider).signOut();
                // Navigate to landing page after sign out
                ref.read(navigationProvider.notifier).state = NavItem.landing;
                // Invalidate user-related providers
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
                    Text(_email.isEmpty ? 'user@example.com' : _email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text('Free Plan', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: const [
                    Icon(Icons.settings_outlined, size: 16),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'subscription',
                child: Row(
                  children: const [
                    Icon(Icons.credit_card_outlined, size: 16),
                    SizedBox(width: 12),
                    Text('Subscription', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: const [
                    Icon(Icons.logout_outlined, size: 16, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sign out', style: TextStyle(fontSize: 14, color: Colors.red)),
                  ],
                ),
              ),
            ],
          );
  }

  // Badge removed as per user request


}

class _OcrReviewDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const _OcrReviewDialog({required this.initialData});

  @override
  State<_OcrReviewDialog> createState() => _OcrReviewDialogState();
}

class _OcrReviewDialogState extends State<_OcrReviewDialog> {
  late TextEditingController _labNameController;
  late TextEditingController _dateController;
  late List<Map<String, dynamic>> _testResults;

  @override
  void initState() {
    super.initState();
    _labNameController = TextEditingController(text: widget.initialData['lab_name']);
    _dateController = TextEditingController(text: widget.initialData['date']);
    _testResults = List<Map<String, dynamic>>.from(
      (widget.initialData['test_results'] as List).map((t) => Map<String, dynamic>.from(t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review Extracted Data'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The AI has extracted the following information. Please verify and correct any errors.', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildField('Lab Name', _labNameController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField('Date (YYYY-MM-DD)', _dateController),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Test Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              ..._testResults.asMap().entries.map((entry) {
                final idx = entry.key;
                final test = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTestField('Name', test['name'] ?? test['test_name'], (v) => _testResults[idx]['name'] = v),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildTestField('Result', test['result']?.toString() ?? test['result_value']?.toString(), (v) => _testResults[idx]['result'] = v),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildTestField('Unit', test['unit'], (v) => _testResults[idx]['unit'] = v),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => setState(() => _testResults.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'lab_name': _labNameController.text,
              'date': _dateController.text,
              'test_results': _testResults,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm & Save'),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTestField(String hint, dynamic initialValue, ValueChanged<String> onChanged) {
    return TextField(
      controller: TextEditingController(text: initialValue?.toString()),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

