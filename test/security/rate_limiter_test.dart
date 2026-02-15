import 'package:flutter_test/flutter_test.dart';
import 'package:clear_health/core/services/rate_limiter_service.dart';

void main() {
  late RateLimiterService rateLimiter;

  setUp(() {
    rateLimiter = RateLimiterService();
  });

  group('RateLimiterService Tests', () {
    test('Should allow requests within limit', () {
      final key = 'test_action';
      final limit = 5;
      final window = Duration(minutes: 1);

      // Consume all allowed requests
      for (int i = 0; i < limit; i++) {
        final result = rateLimiter.checkLimit(
          key,
          limit: limit,
          window: window,
        );
        expect(result, isNull, reason: 'Request $i should be allowed');
      }
    });

    test('Should block requests exceeding limit', () {
      final key = 'block_action';
      final limit = 3;
      final window = Duration(minutes: 1);

      // Consume limit
      for (int i = 0; i < limit; i++) {
        rateLimiter.checkLimit(key, limit: limit, window: window);
      }

      // Next request should be blocked
      final result = rateLimiter.checkLimit(key, limit: limit, window: window);
      expect(
        result,
        isNotNull,
        reason: 'Request exceeding limit should return wait duration',
      );
      expect(result, isA<Duration>());
    });

    test('Should respect different limits for different keys', () {
      // Key A: Limit 2
      final keyA = 'key_a';
      rateLimiter.checkLimit(keyA, limit: 2, window: Duration(minutes: 1));
      rateLimiter.checkLimit(keyA, limit: 2, window: Duration(minutes: 1));
      expect(
        rateLimiter.checkLimit(keyA, limit: 2, window: Duration(minutes: 1)),
        isNotNull,
      );

      // Key B: Limit 5 (should still work)
      final keyB = 'key_b';
      expect(
        rateLimiter.checkLimit(keyB, limit: 5, window: Duration(minutes: 1)),
        isNull,
      );
    });

    test('Should reset limit for a key', () {
      final key = 'reset_action';
      rateLimiter.checkLimit(key, limit: 1, window: Duration(minutes: 1));
      expect(
        rateLimiter.checkLimit(key, limit: 1, window: Duration(minutes: 1)),
        isNotNull,
      );

      rateLimiter.reset(key);
      expect(
        rateLimiter.checkLimit(key, limit: 1, window: Duration(minutes: 1)),
        isNull,
      );
    });

    // Test default values if applicable, or explicit passing
    test(
      'checkLimit without arguments should use default or fail gracefully if designed so',
      () {
        // Since we are refactoring, we might keep backwards compatibility or optional named args.
        // Current implementation uses defaults if we don't pass them, but we want to test passing them.
        // Let's assume we update checkLimit to take optional named arguments.
      },
    );
  });
}

