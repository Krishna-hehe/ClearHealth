import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputValidationService {
  // Singleton pattern not strictly needed with Riverpod, but good for static access if needed

  /// Validates an email address
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Basic email regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null; // Valid
  }

  /// Validates a password (min 8 chars)
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Add more complexity checks as needed
    return null;
  }

  /// Sanitizes generic text input for XSS prevention (basic)
  /// Removes <script> tags and html entities
  String sanitizeInput(String input) {
    var sanitized = input;
    // Remove script tags
    sanitized = sanitized.replaceAll(
      RegExp(r'<script.*?>.*?</script>', caseSensitive: false),
      '',
    );
    // Remove HTML tags (basic)
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    return sanitized.trim();
  }

  /// Validates a numeric lab result
  String? validateLabValue(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return 'Value cannot be negative';
    }
    // Check for astronomical values (sanity check)
    if (number > 100000) {
      return 'Value seems seemingly high, please verify';
    }
    return null;
  }

  /// Validates generic required fields
  String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

final inputValidationServiceProvider = Provider<InputValidationService>((ref) {
  return InputValidationService();
});
