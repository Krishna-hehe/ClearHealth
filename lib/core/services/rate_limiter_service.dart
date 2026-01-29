import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RateLimiterService {
  // Map of Action -> Queue of Timestamps
  final Map<String, Queue<DateTime>> _buckets = {};

  // Config: Max requests per window
  static const int _maxChatRequests = 5;
  static const Duration _chatWindow = Duration(minutes: 1);

  /// Check if an action is allowed. If allowed, records the action.
  /// Returns null if allowed, or time remaining (Duration) if blocked.
  Duration? checkLimit(String actionKey) {
    final now = DateTime.now();
    _buckets.putIfAbsent(actionKey, () => Queue<DateTime>());
    final queue = _buckets[actionKey]!;

    // Prune old timestamps
    while (queue.isNotEmpty && now.difference(queue.first) > _chatWindow) {
      queue.removeFirst();
    }

    if (queue.length >= _maxChatRequests) {
      // Blocked. Calculate wait time based on oldest request expiration
      final oldest = queue.first;
      final expiration = oldest.add(_chatWindow);
      return expiration.difference(now);
    }

    // Allowed
    queue.add(now);
    return null;
  }

  void reset(String actionKey) {
    _buckets.remove(actionKey);
  }
}

final rateLimiterProvider = Provider<RateLimiterService>((ref) {
  return RateLimiterService();
});
