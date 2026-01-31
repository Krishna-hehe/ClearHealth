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
  /// Check if an action is allowed. If allowed, records the action.
  /// Returns null if allowed, or time remaining (Duration) if blocked.
  Duration? checkLimit(
    String actionKey, {
    int limit = _maxChatRequests,
    Duration window = _chatWindow,
  }) {
    final now = DateTime.now();
    _buckets.putIfAbsent(actionKey, () => Queue<DateTime>());
    final queue = _buckets[actionKey]!;

    // Prune old timestamps
    while (queue.isNotEmpty && now.difference(queue.first) > window) {
      queue.removeFirst();
    }

    if (queue.length >= limit) {
      // Blocked. Calculate wait time based on oldest request expiration
      final oldest = queue.first;
      final expiration = oldest.add(window);
      return expiration.difference(now);
    }

    // Allowed
    queue.add(now);
    return null;
  }

  void reset(String actionKey) {
    _buckets.remove(actionKey);
  }

  /// Get current count of requests in the window for an action
  int getUsage(String actionKey, {Duration? window}) {
    final now = DateTime.now();
    final queue = _buckets[actionKey];
    if (queue == null) return 0;

    final effectiveWindow = window ?? _chatWindow;
    return queue.where((dt) => now.difference(dt) <= effectiveWindow).length;
  }

  /// Get all active buckets and their usage
  Map<String, int> getAllUsage({Duration? window}) {
    return _buckets.map(
      (key, _) => MapEntry(key, getUsage(key, window: window)),
    );
  }
}

final rateLimiterProvider = Provider<RateLimiterService>((ref) {
  return RateLimiterService();
});
