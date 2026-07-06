import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../services/database_service.dart';
import '../../../services/ai_matching_service.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/application_model.dart';
import '../../../models/student_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../shared/widgets/certificate_widget.dart';
import '../../../core/utils/certificate_helper.dart';
import 'package:intl/intl.dart';

class OpportunityDetailsScreen extends StatefulWidget {
  final String opportunityId;

  const OpportunityDetailsScreen({super.key, required this.opportunityId});

  @override
  State<OpportunityDetailsScreen> createState() => _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  OpportunityModel? _opportunity;
  String _startupName = 'Bidaya Partner Startup';
  StudentProfileModel? _studentProfile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final List<TextEditingController> _answerControllers = [];
  Stream<List<ApplicationModel>>? _applicationsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _applicationsStream = DatabaseService().getStudentApplications(user.uid);
    }
    _fetchOpportunity();
  }

  void _fetchOpportunity() async {
    final dbService = DatabaseService();
    final user = FirebaseAuth.instance.currentUser;
    final opp = await dbService.getOpportunity(widget.opportunityId);
    
    if (mounted && opp != null) {
      final startupProfile = await dbService.getStartupProfile(opp.startupId);
      StudentProfileModel? profile;
      if (user != null) {
        profile = await dbService.getStudentProfile(user.uid);
      }
      
      setState(() {
        _opportunity = opp;
        _studentProfile = profile;
        if (startupProfile != null) {
          _startupName = startupProfile.companyName;
        }
        for (int i = 0; i < (_opportunity?.questions.length ?? 0); i++) {
          _answerControllers.add(TextEditingController());
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitApplication() async {
    if (_isSubmitting) return;
    if (_opportunity == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if all questions are answered
    for (int i = 0; i < _opportunity!.questions.length; i++) {
      if (_answerControllers[i].text.trim().isEmpty) {
        UIHelper.showError(context, 'Please answer all questions before submitting.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final application = ApplicationModel(
      opportunityId: _opportunity!.id!,
      studentId: user.uid,
      startupId: _opportunity!.startupId,
      answers: _answerControllers.map((c) => c.text.trim()).toList(),
      createdAt: DateTime.now(),
    );

    final dbService = DatabaseService();
    try {
      await dbService.applyToOpportunity(application);

      if (mounted) {
        setState(() => _isSubmitting = false);
        UIHelper.showSuccess(context, 'Application submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        UIHelper.showError(context, e);
      }
    }
  }

  void _declineOffer(ApplicationModel application) async {
    if (_isSubmitting) return;
    debugPrint('🚀 Decline button pressed for app: ${application.id}');
    setState(() => _isSubmitting = true);
    try {
      if (application.id == null) throw 'Invalid application ID';
      await DatabaseService().declineApplication(application.id!);
      debugPrint('✅ Application declined successfully in DB');
      if (mounted) {
        UIHelper.showSuccess(context, 'Offer declined.');
      }
    } catch (e) {
      debugPrint('❌ Error declining offer: $e');
      if (mounted) UIHelper.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _acceptAgreement(ApplicationModel application) async {
    if (_isSubmitting) return;
    debugPrint('🚀 Accept Agreement button pressed for app: ${application.id}');
    setState(() => _isSubmitting = true);
    try {
      if (application.id == null) throw 'Invalid application ID';
      await DatabaseService().acceptAgreement(application.id!);
      debugPrint('✅ Agreement accepted successfully in DB');
      if (mounted) {
        UIHelper.showSuccess(context, 'Agreement accepted! You can now start the task.');
      }
    } catch (e) {
      debugPrint('❌ Error accepting agreement: $e');
      if (mounted) {
        UIHelper.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _markAsComplete(ApplicationModel application) async {
    if (_isSubmitting) return;
    debugPrint('🚀 Mark as Complete button pressed for app: ${application.id}');
    setState(() => _isSubmitting = true);
    try {
      if (application.id == null) throw 'Invalid application ID';
      await DatabaseService().markTaskAsCompletedByStudent(application.id!);
      debugPrint('✅ Task marked as complete in DB');
      if (mounted) {
        UIHelper.showSuccess(context, 'Task marked as complete. Pending startup review.');
      }
    } catch (e) {
      debugPrint('❌ Error marking task as complete: $e');
      if (mounted) UIHelper.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login.')));

    return Scaffold(
      backgroundColor: AppTheme.getAdaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        foregroundColor: AppTheme.getAdaptiveTextPrimary(context),
        title: Text('Opportunity', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<ApplicationModel>>(
            stream: _applicationsStream,
            builder: (context, snapshot) {
              ApplicationModel? currentApp;
              if (snapshot.hasData) {
                try {
                  final apps = snapshot.data!.where((a) => a.opportunityId == widget.opportunityId).toList();
                  if (apps.isEmpty) {
                    currentApp = null;
                  } else {
                    // Prioritize applications that are already progressing over 'pending' ones
                    currentApp = apps.firstWhere(
                      (a) => ['accepted', 'active', 'review_pending', 'completed'].contains(a.status),
                      orElse: () => apps.first, // Fallback to the newest application (since list is sorted by date)
                    );
                  }
                } catch (e) {
                  currentApp = null;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getAdaptivePrimary(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OPEN TASK',
                            style: GoogleFonts.manrope(
                              color: AppTheme.getAdaptivePrimary(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Hero(
                      tag: 'opp-${_opportunity!.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          _opportunity!.title,
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            context.pushNamed(
                              'studentStartupProfile',
                              pathParameters: {'id': _opportunity!.startupId},
                            );
                          },
                          child: Text(
                            _startupName,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (currentApp != null) ...[
                      const SizedBox(height: 32),
                      _buildStatusCard(currentApp),
                    ],
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          _buildInfoItem(Icons.timer_outlined, 'Duration', _opportunity!.duration),
                          const SizedBox(width: 40),
                          _buildInfoItem(Icons.verified_outlined, 'Status', 'Active'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FutureBuilder<StudentProfileModel?>(
                      future: DatabaseService().getStudentProfile(user.uid),
                      builder: (context, profileSnapshot) {
                        if (!profileSnapshot.hasData) return const SizedBox.shrink();
                        return FutureBuilder<AIMatchResult>(
                          future: AIMatchingService().getAIMatch(profileSnapshot.data!, _opportunity!),
                          builder: (context, aiSnapshot) {
                            if (!aiSnapshot.hasData) return const SizedBox.shrink();
                            final result = aiSnapshot.data!;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.secondary.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Match Analysis: ${result.score}%',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.getAdaptivePrimary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    result.explanation,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white.withOpacity(0.9) 
                                          : AppTheme.textPrimary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'About the Task',
                      style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextPrimary(context)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _opportunity!.description,
                      style: GoogleFonts.manrope(fontSize: 15, height: 1.7, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Required Skills',
                      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextPrimary(context)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _opportunity!.requiredSkills.map((skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.getAdaptivePrimary(context).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.getAdaptivePrimary(context).withOpacity(0.1)),
                        ),
                        child: Text(
                          skill,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getAdaptivePrimary(context),
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 40),
                    if (currentApp == null) ...[
                      const Divider(),
                      const SizedBox(height: 32),
                      Text(
                        'Application Form',
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextPrimary(context)),
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(_opportunity!.questions.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _opportunity!.questions[index],
                                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                                    ),
                                    TextSpan(
                                      text: ' *',
                                      style: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _answerControllers[index],
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Type your response here...',
                                  hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: AppTheme.getAdaptiveSurface(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                  ),
                                ),
                                style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                                enabled: true,
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _isSubmitting 
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submitApplication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                'Submit Application',
                                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildStatusCard(ApplicationModel application) {
    final status = application.status;
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_actions;
    String statusTitle = 'Application Pending';
    String statusDesc = 'Your application has been sent and is awaiting review from the startup.';

    if (status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
      statusTitle = 'Application Rejected';
      statusDesc = 'We regret to inform you that your application was not selected at this time.';
    } else if (status == 'accepted') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusTitle = 'Application Accepted!';
      statusDesc = 'Great news! The startup wants to work with you. Please review and accept the agreement to start.';
    } else if (status == 'declined') {
      statusColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;
      statusIcon = Icons.do_not_disturb_on_outlined;
      statusTitle = 'Offer Declined';
      statusDesc = 'You have declined this opportunity.';
    } else if (status == 'active') {
      statusColor = AppTheme.primary;
      statusIcon = Icons.play_circle_outline;
      statusTitle = 'Task Active';
      statusDesc = 'The task is currently in progress. Good luck!';
    } else if (status == 'review_pending') {
      statusColor = Colors.blue;
      statusIcon = Icons.access_time_filled;
      statusTitle = 'Review Pending';
      statusDesc = 'The startup is reviewing your work. You\'ll be notified once they verify it.';
    } else if (status == 'completed') {
      statusColor = Colors.green;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Task Completed';
      statusDesc = 'Well done! The task is complete and your certificate is available below.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          const SizedBox(height: 16),
          Text(
            statusTitle,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18, color: statusColor),
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: (status == 'declined') 
                  ? Colors.black87 
                  : AppTheme.getAdaptiveTextSecondary(context), 
              fontSize: 13, 
              height: 1.5,
              fontWeight: (status == 'declined') ? FontWeight.w600 : null,
            ),
          ),
          if (status == 'accepted' && !_isSubmitting) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _declineOffer(application),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _acceptAgreement(application),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept Agreement'),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'active' && !_isSubmitting) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _markAsComplete(application),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          if (status == 'completed') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final certificateKey = GlobalKey();
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: AppTheme.getAdaptiveSurface(context),
                      insetPadding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: CertificateWidget(
                                  studentName: _studentProfile?.name ?? 'Student',
                                  startupName: _startupName,
                                  taskTitle: _opportunity!.title,
                                  endorsement: application.endorsementLetter ?? '',
                                  date: DateFormat('MMMM dd, yyyy').format(application.createdAt),
                                  boundaryKey: certificateKey,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          CertificateHelper.downloadCertificate(
                                            context: context,
                                            boundaryKey: certificateKey,
                                            fileName: 'Bidaya_Certificate_${_opportunity!.title}',
                                          );
                                        },
                                        icon: const Icon(Icons.download_rounded, size: 18),
                                        label: const Text('Download'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Access Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          if (_isSubmitting) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
           Icon(icon, size: 14, color: AppTheme.getAdaptivePrimary(context)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.getAdaptiveTextSecondary(context), fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextPrimary(context))),
    ],
    );
  }
}
