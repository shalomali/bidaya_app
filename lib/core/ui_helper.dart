import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class UIHelper {
  /// Displays a professional error message to the user.
  static void showError(BuildContext context, dynamic error) {
    final message = _getFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        elevation: 0, // No shadow, use tonal contrast
        shape: StadiumBorder(), // Expressive 2025 standard for floating items
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a branded success message.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green[900], size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                  color: Colors.green[900],
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFC8E6C9), // Tonal green
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: StadiumBorder(),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Maps technical error codes or general errors to user-friendly messages.
  static String _getFriendlyMessage(dynamic error) {
    String rawMessage = '';
    String code = '';

    if (error is FirebaseAuthException) {
      code = error.code;
      rawMessage = error.message ?? '';
    } else if (error is FirebaseException) {
      code = error.code;
      rawMessage = error.message ?? '';
    } else {
      rawMessage = error.toString();
    }

    // Clean up Firebase's default messages which often contain [code] prefixes
    rawMessage = rawMessage.replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();

    // Handle "boxed" technical errors from Flutter Web Release builds
    // These often look like: "Error: Dart exception thrown from converted Future..."
    if (rawMessage.contains('converted Future') || 
        rawMessage.contains('boxed error') ||
        rawMessage.contains('Dart exception')) {
      
      // If we see the signature of our custom error inside the "box" 
      // OR if we are in a state where a transaction likely failed due to capacity
      if (rawMessage.contains('TASK_FULL')) {
        code = 'TASK_FULL';
      } else {
        // FALLBACK: When a transaction fails on web, it often hides the cause.
        // We'll show a more helpful message indicating it might be full.
        return 'Someone else might have just taken the last spot! Please refresh to see the latest status.';
      }
    }

    if (rawMessage.contains('TASK_FULL')) {
      code = 'TASK_FULL';
    }

    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'TASK_FULL':
        return 'Another applicant has already accepted this position. You were just a bit too late! Feel free to explore other amazing opportunities on Bidaya.';
      default:
        // Use the cleaned raw message if it's meaningful, else a fallback
        return rawMessage.isNotEmpty && !rawMessage.contains('Exception')
            ? rawMessage
            : 'Something went wrong. Please try again.';
    }
  }

  /// Builds a professional empty state view.
  static Widget buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.getAdaptivePrimary(context).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: isDark ? AppTheme.secondary.withOpacity(0.5) : Colors.grey[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getAdaptiveTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.getAdaptiveTextSecondary(context),
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
