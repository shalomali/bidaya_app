import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformLauncher {
  static Future<void> launch(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        // Fallback to external application
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
