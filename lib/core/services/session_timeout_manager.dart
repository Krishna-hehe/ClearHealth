import 'dart:async';
import 'package:flutter/material.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback onTimeout;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    required this.duration,
    required this.onTimeout,
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.duration, widget.onTimeout);
  }

  void _resetTimer() {
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
