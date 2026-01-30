// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers/user_providers.dart';
import '../../features/chat/circle_chat_page.dart';

class HealthCirclesPage extends ConsumerStatefulWidget {
  const HealthCirclesPage({super.key});

  @override
  ConsumerState<HealthCirclesPage> createState() => _HealthCirclesPageState();
}

class _HealthCirclesPageState extends ConsumerState<HealthCirclesPage> {
  Future<void> _createCircle(String name) async {
    try {
      await ref.read(userRepositoryProvider).createHealthCircle(name);
      ref.invalidate(healthCirclesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _inviteMember(String circleId, String email, String role) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .inviteMember(circleId, email, role);

      // Force refresh
      ref.invalidate(healthCirclesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _joinCircle(String circleId) async {
    try {
      String id = circleId.trim();
      // Handle full URL
      if (id.contains('/join/')) {
        id = id.split('/join/').last;
      }

      await ref.read(userRepositoryProvider).joinCircle(id);
      ref.invalidate(healthCirclesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined circle successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining: $e')));
      }
    }
  }

  void _showJoinCircleDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Health Circle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the invite link or Circle ID shared with you.',
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Circle Link or ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _joinCircle(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Join Circle'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(String circleId, String circleName) {
    showDialog(
      context: context,
      builder: (context) => _InviteDialog(
        circleName: circleName,
        onInvite: (email, role) => _inviteMember(circleId, email, role),
        inviteLink: 'https://labsense.app/join/$circleId',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final circlesAsync = ref.watch(healthCirclesProvider);

    return circlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (circles) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health Circles',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Securely share your health data with family and doctors.',
                    style: TextStyle(color: AppColors.secondary, fontSize: 16),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Join Circle'),
                    onPressed: _showJoinCircleDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Circle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showCreateCircleDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (circles.isEmpty)
            _buildEmptyState()
          else
            ...circles.map((circle) => _buildCircleCard(circle)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.group_off_outlined, size: 48, color: AppColors.secondary),
          SizedBox(height: 16),
          Text(
            'No Health Circles yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Create one to share your results with family or doctors.',
            style: TextStyle(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard(Map<String, dynamic> circle) {
    final members = (circle['members'] as List?) ?? [];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CircleChatPage(
              circleId: circle['id'],
              circleName: circle['name'] ?? 'Circle',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.group_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        circle['name'] ?? 'Unnamed Circle',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () =>
                        _showInviteDialog(circle['id'], circle['name']),
                    child: const Text('Invite Member'),
                  ),
                ],
              ),
            ),
            if (members.isNotEmpty) const Divider(height: 1),
            if (members.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isPending = member['status'] == 'Pending';
                  final name = member['name'] ?? 'Unknown';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${member['role'] ?? ''} • ${member['permissions'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                    trailing: isPending
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              size: 20,
                              color: AppColors.secondary,
                            ),
                            onPressed: () =>
                                _showPermissionDialog(circle['id'], member),
                          ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(String circleId, Map<String, dynamic> member) {
    String currentPermissions = member['permissions'] ?? 'Read-Only';
    final userId = member['user_id'];

    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Manage Permissions: ${member['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Read-Only'),
                subtitle: const Text('Can view lab results and AI summaries.'),
                value: 'Read-Only',
                groupValue: currentPermissions,
                onChanged: (val) =>
                    setDialogState(() => currentPermissions = val!),
                activeColor: AppColors.primary,
              ),
              RadioListTile<String>(
                title: const Text('Full Access'),
                subtitle: const Text('Can view results and help manage data.'),
                value: 'Full Access',
                groupValue: currentPermissions,
                onChanged: (val) =>
                    setDialogState(() => currentPermissions = val!),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updatePermissions(circleId, userId, currentPermissions);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePermissions(
    String circleId,
    String userId,
    String permissions,
  ) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .updateMemberPermissions(circleId, userId, permissions);
      ref.invalidate(healthCirclesProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permissions updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCreateCircleDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Circle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Circle Name',
                hintText: 'e.g. My Doctors, Family',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Health Circles help you organize how you share data with different groups of people.',
              style: TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _createCircle(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Circle'),
          ),
        ],
      ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  final String circleName;
  final Function(String, String) onInvite;
  final String inviteLink;

  const _InviteDialog({
    required this.circleName,
    required this.onInvite,
    required this.inviteLink,
  });

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite to ${widget.circleName}'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Email'),
                Tab(text: 'Share Link'),
              ],
            ),
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Email Form
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _roleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Relationship',
                            hintText: 'e.g. Doctor, Spouse',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab 2: Link
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Anyone with this link can request to join.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SelectableText(
                            widget.inviteLink,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied to clipboard!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_tabController.index == 0)
          ElevatedButton(
            onPressed: () {
              if (_emailCtrl.text.isNotEmpty && _roleCtrl.text.isNotEmpty) {
                widget.onInvite(_emailCtrl.text, _roleCtrl.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Invite'),
          ),
      ],
    );
  }
}
