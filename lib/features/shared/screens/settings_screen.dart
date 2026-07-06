import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authService = context.read<AuthService>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final userModel = authService.userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingTile(
            context: context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: isDark,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Account'),
          _buildSettingTile(
            context: context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              if (userModel?.role == 'student') {
                context.pushNamed('studentEditProfile');
              } else if (userModel?.role == 'startup') {
                context.pushNamed('startupEditProfile');
              }
            },
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.logout_rounded,
            title: 'Logout',
            textColor: AppTheme.error,
            iconColor: AppTheme.error,
            onTap: () => _showLogoutDialog(context, authService),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'About'),
          _buildSettingTile(
            context: context,
            icon: Icons.info_outline,
            title: 'Privacy Policy',
            onTap: () => _launchURL('https://sites.google.com/view/bidayaprivacypolicy/home'),
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.verified_user_outlined,
            title: 'About Bidaya',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Danger Zone'),
          _buildSettingTile(
            context: context,
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            textColor: AppTheme.error,
            iconColor: AppTheme.error,
            onTap: () => _showDeleteAccountDialog(context, authService),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Version 1.0.0+1',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.getAdaptiveTextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.getAdaptivePrimary(context),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.getAdaptivePrimary(context)),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    await ExternalLauncher.open(url);
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        title: Text('Logout', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authService.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    bool isDeleting = false;
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.getAdaptiveSurface(context),
          title: Text(
            'Delete Account', 
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is permanent and cannot be undone. All your data will be deleted forever.',
                style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              if (!isDeleting) ...[
                Text(
                  'Enter your password to confirm:',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setDialogState(() {}),
                ),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: AppTheme.error),
                  ),
                ),
              ],
            ],
          ),
          actions: isDeleting ? [] : [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: passwordController.text.isEmpty
                ? null 
                : () async {
                  setDialogState(() => isDeleting = true);
                  try {
                    await authService.deleteAccount(passwordController.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      // Auth listener in AppRouter will handle redirect to login
                    }
                  } catch (e) {
                    setDialogState(() => isDeleting = false);
                    String errorMsg = 'An error occurred. Please try again.';
                    
                    if (e is FirebaseAuthException) {
                      switch (e.code) {
                        case 'wrong-password':
                          errorMsg = 'Incorrect password. Please try again.';
                          break;
                        case 'user-mismatch':
                          errorMsg = 'User mismatch. Please log in again.';
                          break;
                        case 'requires-recent-login':
                          errorMsg = 'For security, please logout and log back in before deleting your account.';
                          break;
                        case 'too-many-requests':
                          errorMsg = 'Too many attempts. Please try again later.';
                          break;
                        default:
                          errorMsg = e.message ?? errorMsg;
                      }
                    } else if (e.toString().contains('wrong-password')) {
                      errorMsg = 'Incorrect password. Please try again.';
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                },
              child: Text(
                'Delete Forever', 
                style: TextStyle(
                  color: passwordController.text.isNotEmpty ? AppTheme.error : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.rocket_launch, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.getAdaptivePrimary(context), size: 64),
              const SizedBox(height: 24),
              Text(
                'About Bidaya',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bidaya is a platform connecting ambitious students with innovative startups in the Middle East. Our mission is to bridge the gap between talent and opportunity through AI-powered matching and hands-on tasks.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Version 1.0.0',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
