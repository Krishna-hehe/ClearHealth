import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../core/supabase_service.dart';
import '../core/storage_service.dart';
import '../core/ai_service.dart';
import '../core/providers.dart';
import '../core/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_overlay.dart';
import '../features/lab_results/comparison_page.dart';
import '../features/optimization/recipes_page.dart';
import '../features/community/health_circles_page.dart';
import '../features/home/landing_page.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  String _email = '';
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _email = SupabaseService().currentUser?.email ?? '';
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('has_seen_tour') ?? false;
    final currentUser = SupabaseService().currentUser;
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
    final currentNav = ref.watch(navigationProvider);

    return Stack(
      children: [
        Scaffold(
          body: Column(
            children: [
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
                            child: SingleChildScrollView(
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
                   ref.read(navigationProvider.notifier).state = NavItem.dashboard; // Forces auth check in main.dart
                },
                child: const Text('Log in', style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                   ref.read(navigationProvider.notifier).state = NavItem.dashboard;
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
      error: (_, __) => const SizedBox.shrink(),
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadStatus = 'Uploading document...';
      });

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes');

      final fileName = file.name;
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';

      // 1. Upload to Storage
      final storagePath = await StorageService().uploadLabReport(bytes, fileName);
      if (storagePath == null) throw Exception('Failed to upload to storage');

      setState(() => _uploadStatus = 'Analyzing with AI...');

      // 2. AI Parse (Gemini Vision)
      final parsedData = await AiService.parseLabReport(bytes, mimeType);
      if (parsedData == null) throw Exception('AI failed to parse document');

      // 3. Review Step
      final confirmedData = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _OcrReviewDialog(initialData: parsedData),
      );

      if (confirmedData == null) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        return;
      }

      setState(() => _uploadStatus = 'Saving to records...');

      // 4. Save to Database
      await SupabaseService().createLabResult(confirmedData);

      // 5. Refresh data
      ref.invalidate(labResultsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lab report added successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
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
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search results, tests...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          _buildUpgradeBadge(),
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
                await SupabaseService().signOut();
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

  Widget _buildUpgradeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('Uploads left: ', style: TextStyle(fontSize: 12)),
          const Text('3/3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          const Text(
            'Upgrade',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
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

