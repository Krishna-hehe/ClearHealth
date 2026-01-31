import 'dart:collection';
import 'log_service.dart';

/// Rate Limiter Service
///
/// Implements token bucket algorithm for rate limiting
/// Prevents brute force attacks on authentication and API endpoints
class RateLimiter {
  // Storage for rate limit tracking
  final Map<String, _RateLimitBucket> _buckets = {};

  // Configuration
  final int maxAttempts;
  final Duration window;
  final Duration? lockoutDuration;

  RateLimiter({
    this.maxAttempts = 5,
    this.window = const Duration(minutes: 15),
    this.lockoutDuration,
  });

  /// Check if an action is allowed for the given identifier
  ///
  /// Returns true if allowed, false if rate limit exceeded
  bool isAllowed(String identifier) {
    _cleanupOldBuckets();

    final bucket = _buckets.putIfAbsent(
      identifier,
      () => _RateLimitBucket(maxAttempts, window, lockoutDuration),
    );

    return bucket.tryConsume();
  }

  /// Record a failed attempt (e.g., failed login)
  void recordFailure(String identifier) {
    _cleanupOldBuckets();

    final bucket = _buckets.putIfAbsent(
      identifier,
      () => _RateLimitBucket(maxAttempts, window, lockoutDuration),
    );

    bucket.recordAttempt();

    if (!bucket.isAllowed) {
      AppLogger.warning('🚨 Rate limit exceeded for: $identifier');
    }
  }

  /// Record a successful attempt (resets the counter)
  void recordSuccess(String identifier) {
    _buckets.remove(identifier);
    AppLogger.debug('✅ Rate limit reset for: $identifier');
  }

  /// Get remaining attempts for an identifier
  int getRemainingAttempts(String identifier) {
    final bucket = _buckets[identifier];
    if (bucket == null) return maxAttempts;

    return bucket.remainingAttempts;
  }

  /// Get time until lockout expires
  Duration? getTimeUntilUnlock(String identifier) {
    final bucket = _buckets[identifier];
    if (bucket == null) return null;

    return bucket.timeUntilUnlock;
  }

  /// Check if identifier is currently locked out
  bool isLockedOut(String identifier) {
    final bucket = _buckets[identifier];
    if (bucket == null) return false;

    return bucket.isLockedOut;
  }

  /// Clear rate limit for an identifier (admin function)
  void clearLimit(String identifier) {
    _buckets.remove(identifier);
    AppLogger.info('🔓 Rate limit cleared for: $identifier');
  }

  /// Cleanup old buckets to prevent memory leaks
  void _cleanupOldBuckets() {
    final now = DateTime.now();
    _buckets.removeWhere((key, bucket) {
      // Remove buckets that haven't been used in 2x the window duration
      final inactiveTime = now.difference(bucket.lastAttempt);
      return inactiveTime > window * 2;
    });
  }

  /// Get statistics for monitoring
  Map<String, dynamic> getStats() {
    return {
      'total_tracked': _buckets.length,
      'locked_out': _buckets.values.where((b) => b.isLockedOut).length,
      'near_limit': _buckets.values
          .where((b) => b.remainingAttempts <= 1)
          .length,
    };
  }
}

/// Internal class to track rate limit state for a single identifier
class _RateLimitBucket {
  final int maxAttempts;
  final Duration window;
  final Duration? lockoutDuration;

  final Queue<DateTime> attempts = Queue();
  DateTime? lockoutUntil;
  DateTime lastAttempt = DateTime.now();

  _RateLimitBucket(this.maxAttempts, this.window, this.lockoutDuration);

  bool get isLockedOut {
    if (lockoutUntil == null) return false;

    if (DateTime.now().isBefore(lockoutUntil!)) {
      return true;
    }

    // Lockout expired, clear it
    lockoutUntil = null;
    attempts.clear();
    return false;
  }

  bool get isAllowed {
    if (isLockedOut) return false;

    _removeOldAttempts();
    return attempts.length < maxAttempts;
  }

  int get remainingAttempts {
    if (isLockedOut) return 0;

    _removeOldAttempts();
    return maxAttempts - attempts.length;
  }

  Duration? get timeUntilUnlock {
    if (lockoutUntil == null) return null;

    final remaining = lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  bool tryConsume() {
    if (!isAllowed) return false;

    recordAttempt();
    return true;
  }

  void recordAttempt() {
    lastAttempt = DateTime.now();
    attempts.add(lastAttempt);
    _removeOldAttempts();

    // If we've hit the limit, trigger lockout
    if (attempts.length >= maxAttempts && lockoutDuration != null) {
      lockoutUntil = DateTime.now().add(lockoutDuration!);
      AppLogger.warning('🔒 Lockout triggered until: $lockoutUntil');
    }
  }

  void _removeOldAttempts() {
    final cutoff = DateTime.now().subtract(window);

    while (attempts.isNotEmpty && attempts.first.isBefore(cutoff)) {
      attempts.removeFirst();
    }
  }
}

/// Specialized rate limiters for different use cases
class RateLimiters {
  /// Login attempts - strict limits
  static final login = RateLimiter(
    maxAttempts: 5,
    window: const Duration(minutes: 15),
    lockoutDuration: const Duration(minutes: 15),
  );

  /// Password reset - moderate limits
  static final passwordReset = RateLimiter(
    maxAttempts: 3,
    window: const Duration(hours: 1),
    lockoutDuration: const Duration(hours: 2),
  );

  /// API calls - generous limits
  static final apiCalls = RateLimiter(
    maxAttempts: 100,
    window: const Duration(minutes: 1),
  );

  /// File uploads - moderate limits
  static final fileUpload = RateLimiter(
    maxAttempts: 10,
    window: const Duration(minutes: 5),
  );

  /// AI queries - moderate limits (to prevent API cost abuse)
  static final aiQueries = RateLimiter(
    maxAttempts: 30,
    window: const Duration(minutes: 10),
  );
}
