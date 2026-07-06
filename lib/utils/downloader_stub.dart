import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WebDownloader {
  static Future<void> download(Uint8List bytes, String fileName) async {
    // On Android/iOS: save to temp directory then share
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName.png';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(filePath)], text: 'Bidaya Certificate of Achievement');
  }
}
