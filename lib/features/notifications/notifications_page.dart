import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/navigation.dart';
import '../../core/providers.dart';
import '../../core/providers/user_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  Future<void> _markRead(String id) async {
    await ref.read(userRepositoryProvider).markNotificationAsRead(id);
    // Realtime stream will auto-update
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => ref.read(navigationProvider.notifier).state = NavItem.dashboard,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Dashboard'),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        ),
        const SizedBox(height: 16),
        notificationsAsync.when(
          loading: () => _buildHeader([]),
          error: (e, s) => _buildHeader([]),
          data: (notifications) => _buildHeader(notifications),
        ),
        const SizedBox(height: 32),
        notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (notifications) => notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(notifications),
        ),
      ],
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> notifications) {
    final hasUnread = notifications.any((n) => n['is_read'] == false);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.notifications_none_outlined, size: 24, color: AppColors.secondary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              hasUnread ? 'You have new updates' : 'All caught up!',
              style: const TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_off_outlined, size: 48, color: Theme.of(context).dividerColor),
          SizedBox(height: 24),
          Text('No notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text('We\'ll notify you when your results are ready or when you have new tips.', style: TextStyle(color: AppColors.secondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) => _buildItemTile(notifications[index]),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final bool isRead = item['is_read'] ?? false;
    final DateTime createdAt = DateTime.parse(item['created_at']);
    final String dateStr = DateFormat('MMM d, yyyy').format(createdAt);

    return InkWell(
      onTap: isRead ? null : () => _markRead(item['id'].toString()),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRead ? Theme.of(context).dividerColor.withValues(alpha: 0.1) : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isRead ? Icons.description_outlined : Icons.mark_email_unread_outlined, 
                size: 18, 
                color: isRead ? AppColors.secondary : Theme.of(context).colorScheme.primary
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['title'] ?? 'Update', 
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold, 
                          fontSize: 14,
                          color: isRead ? AppColors.secondary : Theme.of(context).colorScheme.onSurface,
                        )
                      ),
                      Text(dateStr, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['message'] ?? '',
                    style: TextStyle(
                      color: isRead ? AppColors.secondary : Theme.of(context).colorScheme.onSurface, 
                      fontSize: 13, 
                      height: 1.4
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
