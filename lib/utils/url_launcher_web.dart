import 'dart:js' as js;

class PlatformLauncher {
  static Future<void> launch(String url) async {
    js.context.callMethod('open', [url, '_blank']);
  }
}
