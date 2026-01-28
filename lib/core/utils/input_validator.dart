import '../services/log_service.dart';

/// Security utility class for input validation and sanitization
///
/// Implements defense-in-depth approach:
/// 1. Length validation
/// 2. Character whitelisting
/// 3. Format validation
/// 4. SQL injection prevention
class InputValidator {
  // Maximum lengths for different input types
  static const int maxEmailLength = 254; // RFC 5321
  static const int maxNameLength = 100;
  static const int maxTextLength = 500;
  static const int maxLongTextLength = 5000;
  static const int maxPhoneLength = 20;

  /// Sanitize general text input for database storage
  /// Removes control characters and normalizes whitespace
  static String sanitizeText(String input, {int maxLength = maxTextLength}) {
    if (input.isEmpty) return input;

    // Enforce length limit
    if (input.length > maxLength) {
      AppLogger.warning(
        'Input truncated from ${input.length} to $maxLength chars',
      );
      input = input.substring(0, maxLength);
    }

    // Remove control characters (except newline and tab for long text)
    String sanitized = input.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );

    // Normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    return sanitized;
  }

  /// Sanitize name fields (first name, last name, etc.)
  static String sanitizeName(String input) {
    if (input.isEmpty) return input;

    // Names: letters, spaces, hyphens, apostrophes only
    String sanitized = sanitizeText(input, maxLength: maxNameLength);

    // Remove any characters that aren't letters, spaces, hyphens, or apostrophes
    sanitized = sanitized.replaceAll(RegExp(r"[^a-zA-Z\s\-']"), '');

    return sanitized;
  }

  /// Validate and sanitize email
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';

    if (email.length > maxEmailLength) {
      return 'Email is too long (max $maxEmailLength characters)';
    }

    // RFC 5322 simplified regex
    final emailRegex = RegExp(
      r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$''',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    return null; // Valid
  }

  /// Validate phone number
  static String? validatePhone(String phone) {
    if (phone.isEmpty) return null; // Optional field

    if (phone.length > maxPhoneLength) {
      return 'Phone number is too long';
    }

    // Allow digits, spaces, hyphens, parentheses, plus sign
    final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]+$');

    if (!phoneRegex.hasMatch(phone)) {
      return 'Invalid phone number format';
    }

    return null; // Valid
  }

  /// Sanitize numeric input (for lab values, dosages, etc.)
  static String sanitizeNumeric(String input) {
    if (input.isEmpty) return input;

    // Allow digits, decimal point, minus sign, scientific notation
    return input.replaceAll(RegExp(r'[^\d\.\-eE]'), '');
  }

  /// Validate URL
  static String? validateUrl(String url) {
    if (url.isEmpty) return null; // Optional

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Invalid URL format';
      }

      // Only allow http and https
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return 'Only HTTP and HTTPS URLs are allowed';
      }

      return null; // Valid
    } catch (e) {
      return 'Invalid URL format';
    }
  }

  /// Sanitize for SQL (additional layer of defense)
  /// Note: This should be used WITH parameterized queries, not instead of
  static String sanitizeForSql(String input) {
    if (input.isEmpty) return input;

    // Escape single quotes (basic SQL injection prevention)
    // This is a backup - Supabase uses parameterized queries
    return input.replaceAll("'", "''");
  }

  /// Validate date string
  static String? validateDate(String dateStr) {
    if (dateStr.isEmpty) return 'Date is required';

    try {
      DateTime.parse(dateStr);
      return null; // Valid
    } catch (e) {
      return 'Invalid date format';
    }
  }

  /// Sanitize medication/prescription names
  static String sanitizeMedicationName(String input) {
    if (input.isEmpty) return input;

    // Allow letters, numbers, spaces, hyphens, parentheses
    String sanitized = sanitizeText(input, maxLength: maxNameLength);
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\(\)]'), '');

    return sanitized;
  }

  /// Validate and sanitize lab test name
  static String sanitizeLabTestName(String input) {
    if (input.isEmpty) return input;

    // Lab tests: letters, numbers, spaces, hyphens, parentheses, slashes, commas
    String sanitized = sanitizeText(input, maxLength: maxNameLength);
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\(\)/,\.]'), '');

    return sanitized;
  }

  /// Check for common SQL injection patterns (defense in depth)
  static bool containsSqlInjection(String input) {
    if (input.isEmpty) return false;

    final dangerousPatterns = [
      RegExp(
        r'(\bUNION\b|\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b)',
        caseSensitive: false,
      ),
      RegExp(r'(--|;|\/\*|\*\/)', caseSensitive: false),
      RegExp(r'''('|"|`)''', caseSensitive: false),
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        AppLogger.error('🚨 Potential SQL injection detected: $input');
        return true;
      }
    }

    return false;
  }

  /// Validate that input doesn't contain XSS patterns
  static bool containsXss(String input) {
    if (input.isEmpty) return false;

    final xssPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
      RegExp(r'onload=', caseSensitive: false),
    ];

    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(input)) {
        AppLogger.error('🚨 Potential XSS detected: $input');
        return true;
      }
    }

    return false;
  }

  /// Comprehensive validation for user-generated content
  static String? validateUserContent(
    String content, {
    int maxLength = maxLongTextLength,
  }) {
    if (content.isEmpty) return 'Content cannot be empty';

    if (content.length > maxLength) {
      return 'Content is too long (max $maxLength characters)';
    }

    if (containsSqlInjection(content)) {
      return 'Content contains invalid characters';
    }

    if (containsXss(content)) {
      return 'Content contains invalid characters';
    }

    return null; // Valid
  }
}
