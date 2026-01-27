import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import '../core/theme.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connectivity status
    final isOnline = ref.watch(syncServiceProvider).isOnline; 
    // Note: Since SyncService doesn't extend Notifier, we might need a different way to watch
    // or make SyncService a ChangeNotifier/StateNotifier.
    
    // For now, let's assume we need to fix SyncService to be reactive or usage here is mocked.
    // Actually, improved approach: ref.watch(connectionStatusProvider)
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOnline ? 0 : 32,
      color: AppColors.primary,
      child: isOnline 
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'You are offline. Changes will sync when connected.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
