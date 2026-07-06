import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../models/opportunity_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../../core/input_sanitizer.dart';
import '../../shared/widgets/loading_button.dart';

class PostOpportunityScreen extends StatefulWidget {
  final OpportunityModel? opportunity;

  const PostOpportunityScreen({super.key, this.opportunity});

  @override
  State<PostOpportunityScreen> createState() => _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends State<PostOpportunityScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _hiddenDetailsController = TextEditingController();
  final _capacityController = TextEditingController(text: '1');
  
  // Custom questions
  final List<TextEditingController> _questionControllers = [
    TextEditingController()
  ];
  
  // Required Skills
  final _selectedSkills = <String>[];
  final List<String> _availableSkills = [
    'Flutter/Dart', 'React/Next.js', 'Node.js', 'Python', 'Java', 'Kotlin', 'Swift',
    'C++', 'C#', 'UI/UX Design', 'Figma', 'Adobe XD', 'Graphic Design',
    'Machine Learning', 'Data Analysis', 'SQL', 'NoSQL', 'Firebase', 'AWS',
    'Digital Marketing', 'SEO', 'Content Writing', 'Project Management', 'Agile/Scrum',
    'Sales', 'Business Development', 'Finance', 'Accounting', 'Public Speaking',
    'Other...'
  ];
  String? _skillToAdd;
  final _otherSkillController = TextEditingController();
  bool _isAddingOtherSkill = false;
  String? _selectedWorkType = 'Remote'; // New
  final _formKey = GlobalKey<FormState>(); // New

  @override
  void initState() {
    super.initState();
    if (widget.opportunity != null) {
      final opp = widget.opportunity!;
      _titleController.text = opp.title;
      _descriptionController.text = opp.description;
      _durationController.text = opp.duration;
      _hiddenDetailsController.text = opp.hiddenDetails;
      _capacityController.text = opp.maxStudents.toString();
      _selectedWorkType = opp.workType ?? 'Remote';
      _selectedSkills.addAll(opp.requiredSkills);
      
      // Initialize question controllers
      if (opp.questions.isNotEmpty) {
        _questionControllers.clear();
        for (var q in opp.questions) {
          _questionControllers.add(TextEditingController(text: q));
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _hiddenDetailsController.dispose();
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    _otherSkillController.dispose();
    super.dispose();
  }

  void _addCustomSkill() {
    final customSkill = _otherSkillController.text.trim();
    if (customSkill.isEmpty) return;

    if (!_selectedSkills.contains(customSkill)) {
      setState(() {
        _selectedSkills.add(customSkill);
        _otherSkillController.clear();
        _isAddingOtherSkill = false;
      });
    } else {
      UIHelper.showError(context, 'Skill already added.');
    }
  }

  void _finishPosting() async {
    final user = context.read<User?>();
    if (user == null) return;

    if (_selectedSkills.isEmpty) {
      UIHelper.showError(context, 'Please add at least one required skill before posting.');
      return;
    }

    setState(() => _isLoading = true);

    final opportunity = OpportunityModel(
      id: widget.opportunity?.id,
      startupId: user.uid,
      title: InputSanitizer.sanitizeText(_titleController.text),
      description: InputSanitizer.sanitizeText(_descriptionController.text),
      duration: InputSanitizer.sanitizeText(_durationController.text),
      hiddenDetails: InputSanitizer.sanitizeText(_hiddenDetailsController.text),
      questions: _questionControllers
          .map((c) => InputSanitizer.sanitizeText(c.text))
          .where((q) => q.isNotEmpty)
          .toList(),
      requiredSkills: _selectedSkills,
      createdAt: widget.opportunity?.createdAt ?? DateTime.now(),
      workType: _selectedWorkType,
      maxStudents: InputSanitizer.sanitizeInt(_capacityController.text, min: 1, max: 100) ?? 1,
      filledSlots: widget.opportunity?.filledSlots ?? 0,
    );

    final dbService = DatabaseService();
    try {
      if (widget.opportunity != null) {
        await dbService.updateOpportunity(opportunity);
      } else {
        await dbService.createOpportunity(opportunity);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showSuccess(context, widget.opportunity != null ? 'Opportunity updated successfully!' : 'Opportunity posted successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showError(context, e);
      }
    }
  }

  bool get _isDirty {
    return _titleController.text.isNotEmpty ||
           _descriptionController.text.isNotEmpty ||
           _durationController.text.isNotEmpty ||
           _hiddenDetailsController.text.isNotEmpty ||
           _selectedSkills.isNotEmpty;
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    
    if (!_isDirty) {
      if (mounted) context.pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Editing', style: GoogleFonts.manrope(color: AppTheme.textSecondary)),
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
          backgroundColor: AppTheme.getAdaptiveSurface(context),
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handlePop(false),
          ),
          title: Text(widget.opportunity != null ? 'Edit Opportunity' : 'Post Opportunity', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
        ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppTheme.primary,
                onSurface: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              canvasColor: Colors.transparent, // Fixes white artifact in stepper background
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                bool isValid = true;
                if (_currentStep == 0) {
                  if (_titleController.text.trim().isEmpty || 
                      _durationController.text.trim().isEmpty || 
                      _descriptionController.text.trim().isEmpty) {
                    UIHelper.showError(context, 'Please fill in all required fields.');
                    isValid = false;
                  }
                } else if (_currentStep == 1) {
                  if (_hiddenDetailsController.text.trim().isEmpty) {
                    UIHelper.showError(context, 'Internal details are required for security.');
                    isValid = false;
                  }
                } else if (_currentStep == 2) {
                  // questionnaire is optional
                } else if (_currentStep == 3) {
                  if (_selectedSkills.isEmpty) {
                    UIHelper.showError(context, 'Please add at least one required skill for this task.');
                    isValid = false;
                  }
                }

                if (isValid) {
                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                    _finishPosting();
                  }
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
                        child: _currentStep == 3
                            ? LoadingButton(
                                label: widget.opportunity != null ? 'Save Changes' : 'Post Now',
                                isLoading: _isLoading,
                                onPressed: details.onStepContinue,
                              )
                            : ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.getAdaptivePrimary(context),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'Continue',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.primary : Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppTheme.primary),
                            ),
                            child: Text('Back', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text('Basic Info', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                  content: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTextField(_titleController, 'Task Title *', Icons.title_rounded, 'e.g. Flutter Developer Intern', maxLength: 100, textInputAction: TextInputAction.next, autofocus: true),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedWorkType,
                        decoration: InputDecoration(
                          labelText: 'Work Type *',
                          labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.getAdaptiveSurface(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        dropdownColor: AppTheme.getAdaptiveSurface(context),
                        style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                        items: ['Remote', 'Hybrid', 'In-Person'].map((type) => DropdownMenuItem(
                          value: type, 
                          child: Text(type, style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedWorkType = val),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_durationController, 'Expected Duration *', Icons.timer_outlined, 'e.g. 3 Months', maxLength: 50, textInputAction: TextInputAction.next),
                      const SizedBox(height: 16),
                      _buildTextField(_capacityController, 'Number of Students Needed *', Icons.people_outline_rounded, 'e.g. 5', maxLength: 3, keyboardType: TextInputType.number, textInputAction: TextInputAction.next),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: 'Public Description *',
                          labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                          hintText: 'Describe the task and requirements...',
                          hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                          filled: true,
                          fillColor: AppTheme.getAdaptiveSurface(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          counterStyle: GoogleFonts.manrope(fontSize: 10),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Confidential Info', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hidden until agreement is signed.',
                                style: GoogleFonts.manrope(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hiddenDetailsController,
                        maxLines: 5,
                        maxLength: 2000,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Internal Task Details *',
                          labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                          hintText: 'Specify exact tasks, Repo links, or sensitive data...',
                          hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                          filled: true,
                          fillColor: AppTheme.getAdaptiveSurface(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          counterStyle: GoogleFonts.manrope(fontSize: 10),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Questionnaire', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Add questions for applicants to answer.',
                        style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_questionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTextField(_questionControllers[index], 'Question ${index + 1}', Icons.help_outline_rounded, 'Type your question...', maxLength: 200),
                              ),
                              if (_questionControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_rounded, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _questionControllers[index].dispose();
                                      _questionControllers.removeAt(index);
                                    });
                                  },
                                )
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _questionControllers.add(TextEditingController());
                          });
                        },
                        icon: Icon(Icons.add_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary),
                        label: Text('Add Question', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppTheme.primary),
                        ),
                      )
                    ],
                  ),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Required Skills *', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      if (_selectedSkills.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            'At least one skill is required to post this task.',
                            style: GoogleFonts.manrope(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Text(
                        'Which skills are you looking for?',
                        style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Skill',
                          labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.getAdaptiveSurface(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        isExpanded: true,
                        initialValue: _skillToAdd,
                        style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                        dropdownColor: AppTheme.getAdaptiveSurface(context),
                        items: _availableSkills.map((s) => DropdownMenuItem(
                          value: s, 
                          child: Text(s, style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                        )).toList(),
                        onChanged: (val) {
                          if (val == 'Other...') {
                            setState(() {
                              _isAddingOtherSkill = true;
                              _skillToAdd = null;
                            });
                            return;
                          }

                          if (val != null && !_selectedSkills.contains(val)) {
                            setState(() {
                              _selectedSkills.add(val);
                              _isAddingOtherSkill = false;
                            });
                          }
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
                                  hintText: 'e.g. LLM Fine-tuning',
                                  filled: true,
                                  fillColor: AppTheme.getAdaptiveSurface(context),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
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
                      Wrap(
                        spacing: 8,
                        children: _selectedSkills.map((skill) => Chip(
                          label: Text(skill, style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                          onDeleted: () => setState(() => _selectedSkills.remove(skill)),
                          deleteIconColor: Colors.redAccent,
                          backgroundColor: AppTheme.primary.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )).toList(),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    String hint, {
    int? maxLength, 
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool autofocus = false,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: keyboardType == TextInputType.number 
          ? [FilteringTextInputFormatter.digitsOnly] 
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
        hintText: hint,
        hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
        prefixIcon: Icon(icon, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.getAdaptiveSurface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        counterStyle: GoogleFonts.manrope(fontSize: 10),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
    );
  }
}
