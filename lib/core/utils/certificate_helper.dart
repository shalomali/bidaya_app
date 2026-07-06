import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../ui_helper.dart';

class CertificateHelper {
  /// Captures the widget at [boundaryKey] and shares it as a PNG file.
  static Future<void> downloadCertificate({
    required BuildContext context,
    required GlobalKey boundaryKey,
    required String fileName,
  }) async {
    try {
      // 1. Get the RepaintBoundary
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw 'Could not find certificate to capture. Please ensure it is visible on screen.';
      }

      // 2. Capture as Image
      // We use a high pixel ratio for print-quality sharpness
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw 'Failed to generate image data.';
      }
      
      final pngBytes = byteData.buffer.asUint8List();

      // 3. Save to Temporary File
      final tempDir = await getTemporaryDirectory();
      final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final file = await File('${tempDir.path}/$cleanName.png').create();
      await file.writeAsBytes(pngBytes);

      // 4. Share/Download
      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'My Bidaya Certificate - $fileName',
        );
      } else {
        // Fallback or Desktop (if applicable)
        UIHelper.showSuccess(context, 'Certificate saved to temporary storage: ${file.path}');
      }
    } catch (e) {
      debugPrint('Certificate download error: $e');
      if (context.mounted) {
        UIHelper.showError(context, 'Failed to download certificate: $e');
      }
    }
  }
}
