import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers/user_providers.dart';
import '../../core/repositories/user_repository.dart';

class HealthCirclesPage extends ConsumerStatefulWidget {
  const HealthCirclesPage({super.key});

  @override
  ConsumerState<HealthCirclesPage> createState() => _HealthCirclesPageState();
}

class _HealthCirclesPageState extends ConsumerState<HealthCirclesPage> {
  
  Future<void> _createCircle(String name) async {
    try {
      final circles = await ref.read(healthCirclesProvider.future);
      final newCircles = List<Map<String, dynamic>>.from(circles);
      newCircles.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'members': [],
      });
      await ref.read(userRepositoryProvider).updateHealthCircles(newCircles);
      ref.invalidate(healthCirclesProvider);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _inviteMember(String circleId, String email, String role) async {
    try {
      final circles = await ref.read(healthCirclesProvider.future);
      final newCircles = List<Map<String, dynamic>>.from(circles);
      final index = newCircles.indexWhere((c) => c['id'] == circleId);
      if (index != -1) {
         Map<String, dynamic> circle = Map.from(newCircles[index]);
         List members = List.from(circle['members'] ?? []);
         members.add({
           'name': email.split('@')[0], // Placeholder name
           'role': role,
           'status': 'Pending',
           'permissions': 'View Only'
         });
         circle['members'] = members;
         newCircles[index] = circle;
         
         await ref.read(userRepositoryProvider).updateHealthCircles(newCircles);
         ref.invalidate(healthCirclesProvider);
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create New Circle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showCreateCircleDialog,
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
          Text('No Health Circles yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Create one to share your results with family or doctors.', style: TextStyle(color: AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildCircleCard(Map<String, dynamic> circle) {
    final members = (circle['members'] as List?) ?? [];

    return Container(
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
                      child: const Icon(Icons.group_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      circle['name'] ?? 'Unnamed Circle',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _showInviteDialog(circle['id'], circle['name']),
                  child: const Text('Invite Member'),
                ),
              ],
            ),
          ),
          if (members.isNotEmpty) ...[
            const Divider(height: 1),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppColors.primary)),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${member['role'] ?? ''} • ${member['permissions'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                  trailing: isPending
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.secondary),
                          onPressed: () {}, // _showPermissionDialog(member),
                        ),
                );
              },
            ),
          ],
        ],
      ),
    );
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                 _createCircle(controller.text);
                 Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Create Circle'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(String circleId, String circleName) {
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite to $circleName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g. Spouse, Primary Physician',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               if(emailCtrl.text.isNotEmpty && roleCtrl.text.isNotEmpty) {
                 _inviteMember(circleId, emailCtrl.text, roleCtrl.text);
                 Navigator.pop(context);
               }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Send Invitation'),
          ),
        ],
      ),
    );
  }
}
