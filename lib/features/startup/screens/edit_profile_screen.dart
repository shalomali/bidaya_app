import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../../core/input_sanitizer.dart';

class EditStartupProfileScreen extends StatefulWidget {
  const EditStartupProfileScreen({super.key});

  @override
  State<EditStartupProfileScreen> createState() => _EditStartupProfileScreenState();
}

class _EditStartupProfileScreenState extends State<EditStartupProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _industryController = TextEditingController();
  
  String? _selectedWorkType;
  String? _selectedStage;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = context.read<User?>();
    if (user == null) return;

    try {
      final profile = await DatabaseService().getStartupProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile.companyName;
          _descriptionController.text = profile.description;
          _websiteController.text = profile.website ?? '';
          _industryController.text = profile.industry ?? '';
          _selectedWorkType = profile.workType;
          _selectedStage = profile.stage;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading startup profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = context.read<User?>();
    if (user == null) return;

    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      UIHelper.showError(context, 'Company Name and Description are required.');
      return;
    }

    setState(() => _isSaving = true);

    final updatedProfile = StartupProfileModel(
      uid: user.uid,
      companyName: InputSanitizer.sanitizeText(_nameController.text),
      description: InputSanitizer.sanitizeText(_descriptionController.text),
      website: InputSanitizer.sanitizeUrl(_websiteController.text),
      industry: _industryController.text.trim().isEmpty ? null : InputSanitizer.sanitizeText(_industryController.text),
      workType: _selectedWorkType,
      stage: _selectedStage,
    );

    try {
      await DatabaseService().updateStartupProfile(updatedProfile);
      if (mounted) {
        setState(() => _isSaving = false);
        UIHelper.showSuccess(context, 'Startup profile updated successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        UIHelper.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.getAdaptiveSurface(context),
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
          title: Text('Edit Startup Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.getAdaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
        title: Text('Edit Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: AppTheme.getAdaptivePrimary(context),
                fontSize: 16,
              )),
            ),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Company Information'),
                const SizedBox(height: 12),
                _buildCard(Column(
                  children: [
                    _buildTextField(_nameController, 'Company Name *', Icons.business_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(_industryController, 'Industry', Icons.category_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_websiteController, 'Website URL', Icons.language_rounded),
                  ],
                )),
                const SizedBox(height: 24),
                _buildSectionHeader('Operational Details'),
                const SizedBox(height: 12),
                _buildCard(Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWorkType,
                      decoration: _inputDecoration('Primary Work Type', Icons.work_outline),
                      dropdownColor: AppTheme.getAdaptiveSurface(context),
                      style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                      items: ['Remote', 'Hybrid', 'In-Person'].map((type) => DropdownMenuItem(
                        value: type, 
                        child: Text(type, style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedWorkType = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStage,
                      decoration: _inputDecoration('Startup Stage', Icons.auto_graph_rounded),
                      dropdownColor: AppTheme.getAdaptiveSurface(context),
                      style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                      items: ['Seed', 'Series A', 'MVP Stage', 'Growth'].map((stage) => DropdownMenuItem(
                        value: stage, 
                        child: Text(stage, style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedStage = val),
                    ),
                  ],
                )),
                const SizedBox(height: 24),
                _buildSectionHeader('Company Bio'),
                const SizedBox(height: 12),
                _buildCard(
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your startup\'s mission and what you do...',
                      hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Save Changes', style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    )),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.getAdaptivePrimary(context), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getAdaptivePrimary(context), width: 1.5)),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
    );
  }
}
