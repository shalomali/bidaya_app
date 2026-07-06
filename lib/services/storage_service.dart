import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a raw byte array directly to Firebase Storage.
  /// Using Uint8List ensures compatibility with Flutter Web file pickers.
  Future<String?> uploadCV(String uid, Uint8List fileBytes, String originalFileName, {String contentType = 'application/pdf'}) async {
    try {
      // Create a unique file path: cvs/user_id/timestamp_filename.pdf
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
      final path = 'cvs/$uid/${timestamp}_$safeFileName';
      
      final ref = _storage.ref().child(path);
      
      // Upload the raw bytes with a timeout
      final uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: contentType));
      
      // Wait for the upload to complete (max 15 seconds)
      final snapshot = await uploadTask.timeout(const Duration(seconds: 15));
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 5));
      return downloadUrl;
      
    } on TimeoutException catch (_) {
      debugPrint('StorageService Error: Upload timed out. Check Storage Rules or CORS.');
      return null;
    } catch (e) {
      debugPrint('StorageService Error uploading CV: $e');
      return null;
    }
  }

  /// Deletes all files associated with a user (CVs and potential logos).
  Future<void> deleteUserFiles(String uid) async {
    try {
      // 1. Delete CVs
      final cvsRef = _storage.ref().child('cvs/$uid');
      final cvsList = await cvsRef.listAll();
      for (var item in cvsList.items) {
        await item.delete();
      }

      // 2. Delete Startup Logos
      final logosRef = _storage.ref().child('startup_logos/$uid');
      final logosList = await logosRef.listAll();
      for (var item in logosList.items) {
        await item.delete();
      }

      debugPrint('StorageService: Successfully deleted all files for user $uid');
    } catch (e) {
      debugPrint('StorageService Error during data wipe for $uid: $e');
      // We don't rethrow here to ensure the Auth deletion can still proceed 
      // even if storage cleanup has minor issues (e.g. folder doesn't exist)
    }
  }
}
