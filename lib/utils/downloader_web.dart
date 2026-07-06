import 'dart:html' as html;
import 'dart:typed_data';

class WebDownloader {
  static Future<void> download(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.png")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
