class InputValidator {
  static String sanitizeForDb(String input, {int maxLength = 500}) {
    if (input.length > maxLength) {
      throw ArgumentError('Input exceeds maximum length');
    }
    // Remove control characters, normalize whitespace
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                .trim()
                .replaceAll(RegExp(r'\s+'), ' ');
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }
}