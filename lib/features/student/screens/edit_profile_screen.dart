import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/ai_matching_service.dart';
import '../../../models/student_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../../core/input_sanitizer.dart';

class EditStudentProfileScreen extends StatefulWidget {
  const EditStudentProfileScreen({super.key});

  @override
  State<EditStudentProfileScreen> createState() => _EditStudentProfileScreenState();
}

class _EditStudentProfileScreenState extends State<EditStudentProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingCV = false;

  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _bioController = TextEditingController(); // New
  final _portfolioController = TextEditingController(); // New

  final List<Map<String, dynamic>> _selectedSkills = [];
  String? _selectedSkillToAdd;
  Uint8List? _cvBytes;
  String? _cvFileName;
  String? _cvFileType; // New
  String? _existingCvUrl;
  bool _isScanning = false;
  ScanResult? _scanResult;

  final List<String> _availableSkills = [
    'Flutter/Dart', 'React/Next.js', 'Node.js', 'Python', 'Java', 'Kotlin', 'Swift',
    'C++', 'C#', 'UI/UX Design', 'Figma', 'Adobe XD', 'Graphic Design',
    'Machine Learning', 'Data Analysis', 'SQL', 'NoSQL', 'Firebase', 'AWS',
    'Digital Marketing', 'SEO', 'Content Writing', 'Project Management', 'Agile/Scrum',
    'Sales', 'Business Development', 'Finance', 'Accounting', 'Public Speaking',
    'Other...'
  ];

  final _otherSkillController = TextEditingController();
  bool _isAddingOtherSkill = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = context.read<User?>();
    if (user == null) return;

    try {
      final profile = await DatabaseService().getStudentProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile.name;
          _universityController.text = profile.university;
          _majorController.text = profile.major;
          _bioController.text = profile.bio ?? ''; // New
          _portfolioController.text = profile.portfolioUrl ?? ''; // New
          _existingCvUrl = profile.cvUrl;
          _cvFileType = profile.cvFileType;
          _selectedSkills.clear();
          for (final entry in profile.skills.entries) {
            _selectedSkills.add({'name': entry.key, 'level': entry.value});
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
        _selectedSkillToAdd = null;
        _isAddingOtherSkill = false;
      });
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
    setState(() => _selectedSkills.removeWhere((s) => s['name'] == skillName));
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final file = result.files.first;

        // 5MB Limit Check
        const int fiveMb = 5 * 1024 * 1024;
        if (file.size > fiveMb) {
          if (mounted) {
            UIHelper.showError(context, 'CV file size must be less than 5MB.');
          }
          return;
        }

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
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, 'Error selecting file. Please try again.');
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = context.read<User?>();
    if (user == null) return;

    if (_existingCvUrl == null && _cvBytes == null) {
      setState(() => _isSaving = false);
      UIHelper.showError(context, 'Your profile must include a CV (PDF).');
      return;
    }

    setState(() => _isSaving = true);

    String? cvUrl = _existingCvUrl;
    if (_cvBytes != null && _cvFileName != null) {
      setState(() => _isUploadingCV = true);
      final String contentType = _cvFileType == 'pdf' ? 'application/pdf' : 'image/jpeg';
      cvUrl = await StorageService().uploadCV(user.uid, _cvBytes!, _cvFileName!, contentType: contentType);
      setState(() => _isUploadingCV = false);
    }

    if (cvUrl == null) {
      setState(() => _isSaving = false);
      UIHelper.showError(context, 'Failed to upload CV. Please try again.');
      return;
    }

    final updatedProfile = StudentProfileModel(
      uid: user.uid,
      name: InputSanitizer.sanitizeText(_nameController.text),
      university: InputSanitizer.sanitizeText(_universityController.text),
      major: InputSanitizer.sanitizeText(_majorController.text),
      email: user.email ?? '',
      skills: {for (var e in _selectedSkills) e['name'] as String: e['level'] as double},
      cvUrl: cvUrl,
      cvFileName: _cvFileName ?? (_existingCvUrl != null ? 'Existing_CV.pdf' : null),
      cvFileType: _cvFileType,
      bio: _bioController.text.trim().isEmpty ? null : InputSanitizer.sanitizeText(_bioController.text),
      portfolioUrl: InputSanitizer.sanitizeUrl(_portfolioController.text),
      bookmarks: [], 
    );

    try {
      await DatabaseService().updateStudentProfile(updatedProfile);
      if (mounted) {
        setState(() => _isSaving = false);
        UIHelper.showSuccess(context, 'Profile updated successfully!');
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
          iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
          title: Text('Edit Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSaving) {
      return Scaffold(
        backgroundColor: AppTheme.getAdaptiveBackground(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _isUploadingCV ? 'Uploading CV...' : 'Saving Profile...',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 12),
            _buildCard(Column(
              children: [
                _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(_universityController, 'University', Icons.school_outlined),
                const SizedBox(height: 12),
                _buildTextField(_majorController, 'Major / Field', Icons.book_outlined),
                const SizedBox(height: 12),
                _buildTextField(_bioController, 'Bio (Optional)', Icons.edit_note, maxLines: 3, maxLength: 500),
                const SizedBox(height: 12),
                _buildTextField(_portfolioController, 'Portfolio / LinkedIn URL (Optional)', Icons.link, maxLength: 200),
              ],
            )),
            const SizedBox(height: 24),
            _buildSectionHeader('Skills'),
            const SizedBox(height: 12),
            _buildCard(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skill Picker
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSkillToAdd,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Add a skill...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: _availableSkills
                            .where((s) => !_selectedSkills.any((sel) => sel['name'] == s))
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) _addSkill(value);
                        },
                      ),
                    ),
                  ],
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
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: GoogleFonts.manrope(),
                          autofocus: true,
                          onFieldSubmitted: (_) => _addCustomSkill(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addCustomSkill,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary,
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
                const SizedBox(height: 16),
                // Skills list with sliders
                if (_selectedSkills.isEmpty)
                  Text('No skills added yet.', style: GoogleFonts.manrope(color: AppTheme.textSecondary))
                else
                  ..._selectedSkills.map((skill) => _buildSkillRow(skill)),
              ],
            )),
            const SizedBox(height: 24),
            _buildSectionHeader('CV / Resume'),
            const SizedBox(height: 12),
            _buildCard(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_existingCvUrl != null && _cvBytes == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('CV already uploaded', style: GoogleFonts.manrope(color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (_cvBytes != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_cvFileName ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: _pickCV,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_cvBytes != null ? 'Replace CV' : (_existingCvUrl != null ? 'Update CV' : 'Upload CV (PDF/Image)'),
                    style: GoogleFonts.manrope(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 24),
            _buildSectionHeader('AI CV & Portfolio Scanner'),
            const SizedBox(height: 12),
            _buildScannerSection(),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppTheme.getAdaptivePrimary(context),
        letterSpacing: -1,
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, int? maxLength}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.getAdaptivePrimary(context), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getAdaptivePrimary(context), width: 1.5),
        ),
        counterStyle: GoogleFonts.manrope(fontSize: 10),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
    );
  }

  Widget _buildSkillRow(Map<String, dynamic> skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill['name'] as String,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14)),
              Row(
                children: [
                  Text('${(skill['level'] as double).round()}%',
                    style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeSkill(skill['name'] as String),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: skill['level'] as double,
            min: 10,
            max: 100,
            divisions: 9,
            activeColor: AppTheme.primary,
            onChanged: (value) {
              setState(() {
                skill['level'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _scanCvAndPortfolio() async {
    final user = context.read<User?>();
    if (user == null) return;

    if (_existingCvUrl == null && _cvBytes == null) {
      UIHelper.showError(context, 'Please upload a CV first before scanning.');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    try {
      String? cvUrl = _existingCvUrl;
      if (_cvBytes != null && _cvFileName != null) {
        final String contentType = _cvFileType == 'pdf' ? 'application/pdf' : 'image/jpeg';
        cvUrl = await StorageService().uploadCV(user.uid, _cvBytes!, _cvFileName!, contentType: contentType);
        if (cvUrl != null) {
          _existingCvUrl = cvUrl;
          _cvBytes = null;
        }
      }

      if (cvUrl == null) {
        throw 'Please upload a valid CV first.';
      }

      final currentProfile = StudentProfileModel(
        uid: user.uid,
        name: InputSanitizer.sanitizeText(_nameController.text),
        university: InputSanitizer.sanitizeText(_universityController.text),
        major: InputSanitizer.sanitizeText(_majorController.text),
        email: user.email ?? '',
        skills: {for (var e in _selectedSkills) e['name'] as String: e['level'] as double},
        cvUrl: cvUrl,
        cvFileName: _cvFileName ?? (_existingCvUrl != null ? 'Existing_CV.pdf' : null),
        cvFileType: _cvFileType,
        bio: _bioController.text.trim().isEmpty ? null : InputSanitizer.sanitizeText(_bioController.text),
        portfolioUrl: InputSanitizer.sanitizeUrl(_portfolioController.text),
        bookmarks: [],
      );
      await DatabaseService().updateStudentProfile(currentProfile);

      final result = await AIMatchingService().scanCvAndPortfolio(user.uid);
      await _loadExistingProfile();

      if (mounted) {
        setState(() {
          _scanResult = result;
          _isScanning = false;
        });
        UIHelper.showSuccess(context, 'CV and Portfolio scanned successfully! Skills merged.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        UIHelper.showError(context, 'Scan failed: $e');
      }
    }
  }

  Widget _buildScannerSection() {
    if (_isScanning) {
      return _buildCard(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 16),
              Text(
                'AI is analyzing your CV and Portfolio...',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let Gemini scan your uploaded CV and portfolio URL to automatically extract your skills, proficiency levels, and hidden professional signals.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _scanCvAndPortfolio,
                icon: const Icon(Icons.psychology_outlined, color: Colors.white),
                label: Text(
                  'Scan CV & Portfolio',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
        if (_scanResult != null) ...[
          const SizedBox(height: 16),
          _buildCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Scan Results',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Merged Successfully',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        children: [
                          Center(
                            child: CircularProgressIndicator(
                              value: _scanResult!.profileCompleteness / 100.0,
                              strokeWidth: 5,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${_scanResult!.profileCompleteness}%',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Completeness',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI-generated estimation based on your qualifications and credentials.',
                            style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_scanResult!.skills.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Extracted Skills:',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scanResult!.skills.entries.map((entry) {
                      return Chip(
                        label: Text(
                          '${entry.key} (${entry.value.round()}%)',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppTheme.primary.withOpacity(0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                ],
                if (_scanResult!.hiddenSignals.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Hidden Portfolio Signals Found:',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ..._scanResult!.hiddenSignals.map((signal) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber[700], size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              signal,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
