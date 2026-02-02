import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../widgets/glass_card.dart';

class RlsStatusCard extends ConsumerWidget {
  const RlsStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rlsService = ref.watch(rlsVerificationServiceProvider);
    final isVerified = rlsService.isVerified;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isVerified ? Icons.verified_user : Icons.gpp_maybe,
                  color: isVerified ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Row Level Security (RLS)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isVerified
                            ? 'All database policies verified active'
                            : 'Verification pending or re-check required',
                        style: TextStyle(
                          fontSize: 12,
                          color: isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isVerified)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => rlsService.forceVerify(),
                  ),
              ],
            ),
            const Divider(height: 24, color: Colors.white10),
            _buildTableStatus('Profiles', isVerified),
            const SizedBox(height: 8),
            _buildTableStatus('Lab Results', isVerified),
            const SizedBox(height: 8),
            _buildTableStatus('Prescriptions', isVerified),
            const SizedBox(height: 8),
            _buildTableStatus('Medications', isVerified),
          ],
        ),
      ),
    );
  }

  Widget _buildTableStatus(String tableName, bool verified) {
    return Row(
      children: [
        Icon(
          verified ? Icons.check_circle : Icons.radio_button_unchecked,
          color: verified ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(tableName, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          verified ? 'Protected' : 'Pending',
          style: TextStyle(
            fontSize: 11,
            color: verified ? Colors.green.withAlpha(178) : Colors.grey,
          ),
        ),
      ],
    );
  }
}
