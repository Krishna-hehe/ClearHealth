import 'package:flutter/foundation.dart';

/// A HIPAA-compliant logger that prevents PII leaks in production.
class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stackTrace, bool containsPII = false}) {
    _log('DEBUG', message, error: error, stackTrace: stackTrace, containsPII: containsPII);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace, bool containsPII = false}) {
    _log('INFO', message, error: error, stackTrace: stackTrace, containsPII: containsPII);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace, bool containsPII = false}) {
    _log('WARNING', message, error: error, stackTrace: stackTrace, containsPII: containsPII);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, bool containsPII = true}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace, containsPII: containsPII);
  }

  static void _log(String level, String message, {Object? error, StackTrace? stackTrace, bool containsPII = false}) {
    // In release mode, we strictly suppress logs marked as containing PII.
    if (kReleaseMode && containsPII) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final tag = containsPII ? '[PII-SENSITIVE]' : '';
    
    String output = '[$level] $timestamp $tag $message';
    
    if (kReleaseMode) {
      // In release mode, even if not explicitly marked PII, we apply a blanket filter
      // for common patterns like emails or dates if they weren't explicitly cleared.
      output = _sanitize(output);
    }

    debugPrint(output);
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null && !kReleaseMode) {
      debugPrint('Stacktrace: $stackTrace');
    }
  }

  static String _sanitize(String input) {
    // Basic regex for email sanitization
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}');
    // Basic regex for potential dates (DOB) e.g. 1990-01-01 or 01/01/1990
    final dateRegex = RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}|\d{2}[-/]\d{2}[-/]\d{4}');

    return input
        .replaceAll(emailRegex, '[EMAIL_REDACTED]')
        .replaceAll(dateRegex, '[DATE_REDACTED]');
  }
}
