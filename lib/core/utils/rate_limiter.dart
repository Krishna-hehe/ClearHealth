

class RateLimiter {
  final Duration _duration;
  final int _maxRequests;
  final List<DateTime> _requests = [];

  RateLimiter({
    Duration duration = const Duration(minutes: 1),
    int maxRequests = 10,
  })  : _duration = duration,
        _maxRequests = maxRequests;

  bool canRequest() {
    final now = DateTime.now();
    _requests.removeWhere((time) => now.difference(time) > _duration);

    if (_requests.length < _maxRequests) {
      _requests.add(now);
      return true;
    }
    return false;
  }
  
  Duration get timeUntilNextRequest {
    if (_requests.isEmpty) return Duration.zero;
    final now = DateTime.now();
    final firstRequest = _requests.first;
    final expiresAt = firstRequest.add(_duration);
    final diff = expiresAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}
