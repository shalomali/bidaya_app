import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';

class StartupSetupScreen extends StatefulWidget {
  const StartupSetupScreen({super.key});

  @override
  State<StartupSetupScreen> createState() => _StartupSetupScreenState();
}

class _StartupSetupScreenState extends State<StartupSetupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _industryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  String? _selectedWorkType = 'Remote';
  String? _selectedStage = 'MVP';

  final List<String> _workTypes = ['Remote', 'Hybrid', 'In-Person'];
  final List<String> _stages = ['Ideation', 'MVP', 'Seed', 'Series A', 'Growth'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  void _finishSetup() async {
    if (_formKey.currentState!.validate()) {
      final user = context.read<User?>();
      if (user == null) return;

      setState(() => _isSaving = true);

      final profile = StartupProfileModel(
        uid: user.uid,
        companyName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        industry: _industryController.text.trim(),
        workType: _selectedWorkType,
        stage: _selectedStage,
      );

      final dbService = DatabaseService();
      try {
        await dbService.updateStartupProfile(profile);
        if (mounted) {
          setState(() => _isSaving = false);
          await context.read<AuthService>().markProfileComplete();
          if (mounted) {
            context.goNamed('startupDashboard');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          UIHelper.showError(context, e);
        }
      }
    }
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    
    final isDirty = _nameController.text.isNotEmpty || 
                    _descriptionController.text.isNotEmpty || 
                    _industryController.text.isNotEmpty;
    
    if (!isDirty) {
      // If no changes, still block back button to dashboard.
      // They can only leave by signing out.
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to stop setting up your profile? Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continue Setup', style: GoogleFonts.manrope(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: Scaffold(
        backgroundColor: AppTheme.getAdaptiveBackground(context),
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove default back button
          title: Text('Company Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('You will need to complete your profile later to access the platform.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent))
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  context.read<AuthService>().signOut();
                }
              },
            ),
          ],
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.getAdaptivePrimary(context).withOpacity(0.1),
                    child: Icon(Icons.business_rounded, size: 48, color: AppTheme.getAdaptivePrimary(context)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Setup Startup Profile',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getAdaptiveTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile to start posting opportunities',
                  style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextSecondary(context), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildFieldLabel('Company Name'),
                const SizedBox(height: 8),
                _buildTextField(_nameController, 'Enter company name', Icons.business_outlined),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Work Arrangement'),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            value: _selectedWorkType,
                            items: _workTypes,
                            onChanged: (val) => setState(() => _selectedWorkType = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Current Stage'),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            value: _selectedStage,
                            items: _stages,
                            onChanged: (val) => setState(() => _selectedStage = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('Industry / Domain'),
                const SizedBox(height: 8),
                _buildTextField(_industryController, 'e.g. Fintech, EdTech', Icons.category_outlined),
                const SizedBox(height: 24),
                _buildFieldLabel('Short Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'What does your startup do?',
                    filled: true,
                    fillColor: AppTheme.getAdaptiveSurface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))
                    ),
                  ),
                  style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context)),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 48),
                _isSaving 
                  ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _finishSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.getAdaptivePrimary(context),
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF003735) : Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Save & Continue',
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.getAdaptiveTextColor(context),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppTheme.getAdaptiveSurface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))
        ),
      ),
      style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context)),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: AppTheme.getAdaptivePrimary(context)),
          style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context), fontSize: 15),
          dropdownColor: AppTheme.getAdaptiveSurface(context),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context))),
            );
          }).toList(),
        ),
      ),
    );
  }
}
