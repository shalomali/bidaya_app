import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidaya_app/core/ui_helper.dart';
import 'package:bidaya_app/core/theme.dart';
import 'package:bidaya_app/services/database_service.dart';
import 'package:bidaya_app/services/auth_service.dart';
import 'package:bidaya_app/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingRole();
    });
  }

  void _checkExistingRole() {
    final authService = context.read<AuthService>();
    final role = authService.userModel?.role;
    if (role != null && role.isNotEmpty) {
      debugPrint('RoleSelection: Role already exists ($role), skipping...');
      context.go(role == 'student' ? '/student/setup' : '/startup/setup');
    }
  }

  void _selectRole(BuildContext context, String role) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final user = context.read<User?>();
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final dbService = DatabaseService();
    try {
      await dbService.updateUserData(UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: role,
      ));

      if (mounted) {
        final authService = context.read<AuthService>();
        await authService.refreshUserData();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (role == 'student') {
            context.goNamed('studentSetup');
          } else {
            context.goNamed('startupSetup');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showError(context, e);
      }
    }
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out?', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: const Text('You need to select a role to continue. Would you like to sign out instead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay', style: GoogleFonts.manrope(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              context.read<AuthService>().signOut();
            },
            child: Text('Sign Out', style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Sign out is handled in the action
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handlePop(false),
          ),
          title: const Text('Choose Your Path'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How do you want to use Bidaya?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _RoleCard(
                  title: 'I am a Student',
                  description: 'Build your profile, prove your skills, and match with exciting opportunities.',
                  icon: Icons.school_outlined,
                  onTap: () => _selectRole(context, 'student'),
                ),
                const SizedBox(height: 24),
                _RoleCard(
                  title: 'I am a Startup',
                  description: 'Post tasks, evaluate talent, and find the perfect match for your needs.',
                  icon: Icons.business_center_outlined,
                  onTap: () => _selectRole(context, 'startup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
