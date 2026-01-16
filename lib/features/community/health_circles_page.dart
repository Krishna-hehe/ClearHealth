import 'package:flutter/material.dart';
import '../../core/theme.dart';

class HealthCirclesPage extends StatefulWidget {
  const HealthCirclesPage({super.key});

  @override
  State<HealthCirclesPage> createState() => _HealthCirclesPageState();
}

class _HealthCirclesPageState extends State<HealthCirclesPage> {
  final List<Map<String, dynamic>> _circles = [
    {
      'id': '1',
      'name': 'Family Circle',
      'members': [
        {'name': 'Sarah Johnson', 'role': 'Spouse', 'status': 'Accepted', 'permissions': 'Full Access'},
        {'name': 'Michael Chen', 'role': 'Brother', 'status': 'Pending', 'permissions': 'View Only'},
      ],
    },
    {
      'id': '2',
      'name': 'Medical Team',
      'members': [
        {'name': 'Dr. Emily Smith', 'role': 'Primary Doctor', 'status': 'Accepted', 'permissions': 'Lab Reports & Trends'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
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
        ..._circles.map((circle) => _buildCircleCard(circle)),
      ],
    );
  }

  Widget _buildCircleCard(Map<String, dynamic> circle) {
    final members = circle['members'] as List;

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
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.group_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      circle['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _showInviteDialog(circle['name']),
                  child: const Text('Invite Member'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              final isPending = member['status'] == 'Pending';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.border.withOpacity(0.5),
                  child: Text(member['name'][0], style: const TextStyle(color: AppColors.primary)),
                ),
                title: Text(
                  member['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${member['role']} • ${member['permissions']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.secondary),
                        onPressed: () => _showPermissionDialog(member),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.secondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateCircleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Circle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Create Circle'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(String circleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite to $circleName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Send Invitation'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Permissions: ${member['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPermissionToggle('Lab Results', true, (v) {}),
              _buildPermissionToggle('Trends & Analysis', true, (v) {}),
              _buildPermissionToggle('Prescriptions', false, (v) {}),
              _buildPermissionToggle('Health Chat History', false, (v) {}),
              _buildPermissionToggle('Conditions', true, (v) {}),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
