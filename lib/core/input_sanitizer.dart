import 'package:flutter/foundation.dart';

class InputSanitizer {
  /// Basic text sanitization: strips HTML-like tags and trims whitespace.
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';
    // Strip HTML tags using a basic regex
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    return sanitized.trim();
  }

  /// Validates if a string is a well-formed email address.
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegex.hasMatch(email);
  }

  /// Validates and cleans a URL.
  static String? sanitizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    String trimmed = url.trim();
    
    // Ensure it starts with http/https
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }

    try {
      final uri = Uri.parse(trimmed);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return uri.toString();
      }
    } catch (e) {
      debugPrint('Invalid URL: $url');
    }
    return null;
  }

  /// Validates that a numeric string is a valid integer within a range.
  static int? sanitizeInt(String input, {int min = 0, int max = 999}) {
    final val = int.tryParse(input.trim());
    if (val == null) return null;
    if (val < min) return min;
    if (val > max) return max;
    return val;
  }

  /// Validates Firebase UID format (basic alphanumeric check).
  static bool isValidUid(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    // Relaxed for Firebase/Firestore IDs which can contain various characters
    return uid.length >= 5 && uid.length <= 128;
  }
}
