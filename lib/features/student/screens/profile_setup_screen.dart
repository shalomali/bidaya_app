import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/student_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../../core/input_sanitizer.dart';
import '../../shared/widgets/loading_button.dart';

class StudentSetupScreen extends StatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  State<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends State<StudentSetupScreen> {
  int _currentStep = 0;
  bool _isSaving = false;
  
  // Controllers for basic info
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _bioController = TextEditingController(); // New
  final _portfolioController = TextEditingController(); // New
  final _personalInfoFormKey = GlobalKey<FormState>();
  
  // Dynamic skills data
  final List<Map<String, dynamic>> _selectedSkills = [];
  
  // CV Upload Data
  Uint8List? _cvBytes;
  String? _cvFileName;
  String? _cvFileType; // New
  bool _isUploadingCV = false;
  
  // Comprehensive list of available skills
  final List<String> _availableSkills = [
    'Flutter/Dart', 'React/Next.js', 'Node.js', 'Python', 'Java', 'Kotlin', 'Swift',
    'C++', 'C#', 'UI/UX Design', 'Figma', 'Adobe XD', 'Graphic Design',
    'Machine Learning', 'Data Analysis', 'SQL', 'NoSQL', 'Firebase', 'AWS',
    'Digital Marketing', 'SEO', 'Content Writing', 'Project Management', 'Agile/Scrum',
    'Sales', 'Business Development', 'Finance', 'Accounting', 'Public Speaking',
    'Other...'
  ];

  String? _selectedSkillToAdd;
  final _otherSkillController = TextEditingController();
  bool _isAddingOtherSkill = false;

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _bioController.dispose();
    _portfolioController.dispose();
    _otherSkillController.dispose();
    super.dispose();
  }

  void _addSkill(String skillName) {
    if (skillName == 'Other...') {
      setState(() {
        _isAddingOtherSkill = true;
        _selectedSkillToAdd = null;
      });
      return;
    }

    if (!_selectedSkills.any((s) => s['name'] == skillName)) {
      setState(() {
        _selectedSkills.add({'name': skillName, 'level': 50.0});
        _selectedSkillToAdd = null; // Reset dropdown
        _isAddingOtherSkill = false;
      });
    } else {
      UIHelper.showError(context, 'Skill already added.');
    }
  }

  void _addCustomSkill() {
    final customSkill = _otherSkillController.text.trim();
    if (customSkill.isEmpty) return;

    if (!_selectedSkills.any((s) => s['name'].toLowerCase() == customSkill.toLowerCase())) {
      setState(() {
        _selectedSkills.add({'name': customSkill, 'level': 50.0});
        _otherSkillController.clear();
        _isAddingOtherSkill = false;
      });
    } else {
      UIHelper.showError(context, 'Skill already added.');
    }
  }

  void _removeSkill(String skillName) {
    setState(() {
      _selectedSkills.removeWhere((s) => s['name'] == skillName);
    });
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // 5MB Limit Check
        const int fiveMb = 5 * 1024 * 1024;
        if (file.size > fiveMb) {
          if (mounted) {
            UIHelper.showError(context, 'CV file size must be less than 5MB.');
          }
          return;
        }

        if (file.bytes != null) {
          setState(() {
            _cvBytes = file.bytes;
            _cvFileName = file.name;
            // Determine type
            final ext = file.extension?.toLowerCase();
            if (ext == 'pdf') {
              _cvFileType = 'pdf';
            } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
              _cvFileType = 'image';
            } else {
              _cvFileType = 'other';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        UIHelper.showError(context, 'Error selecting file. Please try again.');
      }
    }
  }

  void _finishSetup() async {
    final user = context.read<User?>();
    if (user == null) return;

    setState(() => _isSaving = true);
    String? uploadedCvUrl;

    if (_cvBytes == null || _cvFileName == null) {
      setState(() => _isSaving = false);
      UIHelper.showError(context, 'Please upload your CV (PDF) to continue.');
      return;
    }

    setState(() => _isUploadingCV = true);
    final String contentType = _cvFileType == 'pdf' ? 'application/pdf' : 'image/jpeg'; // Simplification for images
    uploadedCvUrl = await StorageService().uploadCV(user.uid, _cvBytes!, _cvFileName!, contentType: contentType);
    setState(() => _isUploadingCV = false);

    if (uploadedCvUrl == null) {
      setState(() => _isSaving = false);
      UIHelper.showError(context, 'Failed to upload CV. Please try again.');
      return;
    }

    final profile = StudentProfileModel(
      uid: user.uid,
      name: InputSanitizer.sanitizeText(_nameController.text),
      university: InputSanitizer.sanitizeText(_universityController.text),
      major: InputSanitizer.sanitizeText(_majorController.text),
      email: user.email ?? '',
      skills: { for (var e in _selectedSkills) e['name'] : e['level'] },
      cvUrl: uploadedCvUrl,
      cvFileName: _cvFileName,
      cvFileType: _cvFileType,
      bio: _bioController.text.trim().isEmpty ? null : InputSanitizer.sanitizeText(_bioController.text),
      portfolioUrl: InputSanitizer.sanitizeUrl(_portfolioController.text),
      bookmarks: [],
    );

    final dbService = DatabaseService();
    try {
      await dbService.updateStudentProfile(profile);
      if (mounted) {
        setState(() => _isSaving = false);
        await context.read<AuthService>().markProfileComplete();
        if (mounted) {
          context.goNamed('studentDashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        UIHelper.showError(context, e);
      }
    }
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    
    final isDirty = _nameController.text.isNotEmpty || 
                    _universityController.text.isNotEmpty || 
                    _majorController.text.isNotEmpty ||
                    _bioController.text.isNotEmpty ||
                    _selectedSkills.isNotEmpty ||
                    _cvBytes != null;
    
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
          title: Text('Complete Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
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
      body: _isSaving 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _isUploadingCV ? 'Uploading CV...' : 'Saving Profile...',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600, 
                    color: AppTheme.getAdaptiveTextSecondary(context)
                  ),
                ),
              ],
            ),
          )
        : Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.getAdaptivePrimary(context)),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_personalInfoFormKey.currentState!.validate()) {
                    setState(() => _currentStep += 1);
                  }
                } else if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _finishSetup();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: _currentStep == 2 
                            ? LoadingButton(
                                label: 'Finish Setup',
                                isLoading: _isSaving,
                                onPressed: details.onStepContinue,
                              )
                            : ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.getAdaptivePrimary(context),
                                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF003735) : Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Continue'),
                              ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text('Personal Info', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextColor(context))),
                  content: Form(
                    key: _personalInfoFormKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildTextField(_nameController, 'Full Name', Icons.person_outline, required: true, textInputAction: TextInputAction.next, autofocus: true),
                        const SizedBox(height: 16),
                        _buildTextField(_universityController, 'University', Icons.school_outlined, required: true, textInputAction: TextInputAction.next),
                        const SizedBox(height: 16),
                        _buildTextField(_majorController, 'Major / Field of Study', Icons.book_outlined, required: true, textInputAction: TextInputAction.next),
                        const SizedBox(height: 24),
                        // Grouping secondary fields in a Card (Hick's Law)
                        Card(
                          color: AppTheme.getAdaptiveSurface(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05))),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Additional Details', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.getAdaptivePrimary(context))),
                                const SizedBox(height: 16),
                                _buildTextField(_bioController, 'Bio (Optional)', Icons.edit_note, maxLines: 3, maxLength: 500, textInputAction: TextInputAction.next),
                                const SizedBox(height: 16),
                                _buildTextField(_portfolioController, 'Portfolio / LinkedIn URL (Optional)', Icons.link, maxLength: 200, textInputAction: TextInputAction.done, keyboardType: TextInputType.url),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Skills & Proficiency', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextColor(context))),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                        Text(
                        'Select your skills and assess your current level',
                        style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextSecondary(context), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Add a Skill',
                          filled: true,
                          fillColor: AppTheme.getAdaptiveSurface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                          prefixIcon: const Icon(Icons.add_circle_outline),
                        ),
                        isExpanded: true,
                        initialValue: _selectedSkillToAdd,
                        items: _availableSkills.map((String skill) {
                          return DropdownMenuItem<String>(
                            value: skill,
                            child: Text(skill, style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context))),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) _addSkill(newValue);
                        },
                      ),
                      if (_isAddingOtherSkill) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _otherSkillController,
                                decoration: InputDecoration(
                                  labelText: 'Enter Custom Skill',
                                  hintText: 'e.g. Prompt Engineering',
                                  filled: true,
                                  fillColor: AppTheme.getAdaptiveSurface(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                  ),
                                ),
                                style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context)),
                                autofocus: true,
                                onFieldSubmitted: (_) => _addCustomSkill(),
                              ),
                            ),
                            const SizedBox(width: 8),
                             IconButton.filled(
                               onPressed: _addCustomSkill,
                               icon: const Icon(Icons.add_rounded),
                               style: IconButton.styleFrom(
                                 backgroundColor: AppTheme.getAdaptivePrimary(context),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _isAddingOtherSkill = false),
                              icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_selectedSkills.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'No skills added yet.',
                              style: GoogleFonts.manrope(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        ..._selectedSkills.map((skill) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.getAdaptiveSurface(context),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      skill['name'],
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 15,
                                        color: AppTheme.getAdaptiveTextColor(context),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.red),
                                      onPressed: () => _removeSkill(skill['name']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: skill['level'],
                                        min: 0,
                                        max: 100,
                                        divisions: 20,
                                         activeColor: AppTheme.getAdaptivePrimary(context),
                                        onChanged: (value) => setState(() => skill['level'] = value),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${skill['level'].round()}%', 
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 12,
                                          color: AppTheme.getAdaptiveTextColor(context),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Verification', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextColor(context))),
                  content: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                           color: AppTheme.getAdaptiveSurface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cvBytes != null ? Colors.green[200]! : Colors.grey[200]!, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _cvBytes != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                              size: 48,                               color: _cvBytes != null ? Colors.green : AppTheme.getAdaptivePrimary(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _cvFileName != null ? _cvFileName! : 'Upload your CV (PDF or Image) *Required',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                                color: _cvFileName != null ? AppTheme.getAdaptiveTextColor(context) : Colors.redAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: _pickCV,
                              icon: const Icon(Icons.attach_file, size: 18),
                              label: Text(_cvBytes != null ? 'Change File' : 'Select PDF/Image'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputAction? textInputAction,
    bool autofocus = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      autofocus: autofocus,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppTheme.getAdaptiveSurface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        counterStyle: GoogleFonts.manrope(fontSize: 10, color: AppTheme.getAdaptiveTextSecondary(context)),
      ),
      style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context)),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }
}
