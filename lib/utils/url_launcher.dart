// Conditional import for web
import 'url_launcher_web.dart' if (dart.library.io) 'url_launcher_mobile.dart';

class ExternalLauncher {
  static Future<void> open(String url) async {
    await PlatformLauncher.launch(url);
  }
}
