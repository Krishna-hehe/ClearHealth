import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Simple mock provider for now, replacing with real logic later
final streakProvider = FutureProvider<int>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 500));
  // Return a mock streak of 5 days
  return 5;
});

class StreakFlame extends ConsumerWidget {
  const StreakFlame({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox(),
      data: (streak) {
        if (streak == 0) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Icon(FontAwesomeIcons.fire, color: Colors.white, size: 14),
               const SizedBox(width: 8),
               Text(
                 '$streak Day Streak',
                 style: const TextStyle(
                   color: Colors.white, 
                   fontWeight: FontWeight.bold, 
                   fontSize: 12,
                 ),
               ),
            ],
          ),
        );
      },
    );
  }
}
