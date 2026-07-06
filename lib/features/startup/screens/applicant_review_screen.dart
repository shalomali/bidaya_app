import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../models/user_model.dart';
import '../../../models/application_model.dart';
import '../../../models/student_profile_model.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../../utils/url_launcher.dart';
import '../../shared/widgets/cv_preview_modal.dart';

class ApplicantReviewScreen extends StatefulWidget {
  final String opportunityId;
  final String? applicantId;

  const ApplicantReviewScreen({
    super.key, 
    required this.opportunityId,
    this.applicantId,
  });

  @override
  State<ApplicantReviewScreen> createState() => _ApplicantReviewScreenState();
}

class _ApplicantReviewScreenState extends State<ApplicantReviewScreen> {
  final DatabaseService _dbService = DatabaseService();
  OpportunityModel? _opportunity;
  // bool _isOppLoading = true;
  bool _hasDeepLinked = false;

  @override
  void initState() {
    super.initState();
    _fetchOpportunity();
  }

  void _fetchOpportunity() async {
    final opp = await _dbService.getOpportunity(widget.opportunityId);
    if (mounted) {
      setState(() {
        _opportunity = opp;
        // _isOppLoading = false;
      });
    }
  }

  void _updateStatus(String applicationId, String newStatus) async {
    await _dbService.updateApplicationStatus(applicationId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applicant marked as $newStatus'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showApplicantDetails(ApplicationModel application) async {
    try {
      debugPrint('Reviewing applicant: ${application.id} for student: ${application.studentId}');
      final profile = await _dbService.getStudentProfile(application.studentId);
      
      if (profile == null) {
        debugPrint('❌ Error: Profile not found for ${application.studentId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not load student profile.')),
          );
        }
        return;
      }
      
      if (!mounted) {
        debugPrint('❌ Error: Context no longer mounted');
        return;
      }

      debugPrint('🚀 Opening details for ${profile.name}');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getAdaptivePrimary(context),
                              ),
                            ),
                            Text(
                              '${profile.major} @ ${profile.university}',
                              style: GoogleFonts.manrope(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: application.status == 'declined' 
                              ? Colors.red.withOpacity(0.15) 
                              : application.status == 'rejected'
                                  ? Colors.grey.withOpacity(0.15)
                                  : application.status == 'accepted' || application.status == 'active'
                                      ? Colors.green.withOpacity(0.15)
                                      : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          application.status.toUpperCase(),
                          style: GoogleFonts.manrope(
                            color: application.status == 'declined' 
                                ? Colors.red 
                                : application.status == 'rejected'
                                    ? AppTheme.getAdaptiveTextSecondary(context)
                                    : application.status == 'accepted' || application.status == 'active'
                                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.green[700])
                                        : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Profile Highlights'),
                  const SizedBox(height: 16),
                  _buildDetailLabel(context, 'Bio'),
                  Text(profile.bio ?? 'No bio provided.', style: GoogleFonts.manrope(height: 1.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _buildDetailLabel(context, 'Portfolio'),
                  (profile.portfolioUrl != null && profile.portfolioUrl!.isNotEmpty)
                      ? InkWell(
                          onTap: () => ExternalLauncher.open(profile.portfolioUrl!),
                          child: Text(
                            profile.portfolioUrl!,
                            style: GoogleFonts.manrope(color: AppTheme.getAdaptivePrimary(context), decoration: TextDecoration.underline),
                          ),
                        )
                      : Text('No portfolio linked.', style: GoogleFonts.manrope(color: Colors.grey)),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Academic CV'),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getAdaptiveBackground(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, color: AppTheme.getAdaptivePrimary(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            profile.cvFileName ?? 'Student CV',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                          ),
                        ),
                        TextButton.icon(
                            onPressed: () => _showNewCVPreview(profile),
                            icon: const Icon(Icons.description_outlined, size: 20, color: AppTheme.primary),
                            label: Text('View CV', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.getAdaptivePrimary(context),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Skills & Proficiency'),
                  const SizedBox(height: 16),
                  ...profile.skills.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
                            Text('${e.value.round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.getAdaptivePrimary(context))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: e.value / 100,
                            minHeight: 10,
                            backgroundColor: AppTheme.getAdaptivePrimary(context).withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.getAdaptivePrimary(context)),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Completed Work History'),
                  const SizedBox(height: 16),
                  StreamBuilder<List<ApplicationModel>>(
                    stream: _dbService.getStudentCompletedApplications(application.studentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final completedApps = snapshot.data ?? [];
                      if (completedApps.isEmpty) {
                        return Text(
                          'No completed tasks yet.',
                          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.getAdaptiveTextSecondary(context)),
                        );
                      }
                      return Column(
                        children: completedApps.map((compApp) => _buildCompletedTaskSnippet(compApp)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Application Answers'),
                  const SizedBox(height: 16),
                  if (application.answers.isEmpty)
                    Text('No specific questions were answered.', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.getAdaptiveTextSecondary(context)))
                  else
                    ...application.answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      final String question = (_opportunity != null && _opportunity!.questions.length > index)
                          ? _opportunity!.questions[index]
                          : 'QUESTION ${index + 1}';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.getAdaptiveBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.toUpperCase(),
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.getAdaptivePrimary(context),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              answer,
                              style: GoogleFonts.manrope(
                                height: 1.5, 
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  const SizedBox(height: 16),
                  if (['pending', 'accepted', 'active', 'review_pending', 'completed'].contains(application.status)) ...[
                    _buildDetailLabel(context, 'Contact Email'),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 16, color: AppTheme.getAdaptivePrimary(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: (profile.email.isNotEmpty)
                              ? SelectableText(
                                  profile.email,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                                  ),
                                )
                              : FutureBuilder<UserModel?>(
                                  future: DatabaseService().getUserData(application.studentId),
                                  builder: (context, userSnapshot) {
                                    final email = userSnapshot.data?.email ?? 'Email not found';
                                    return SelectableText(
                                      email,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (application.status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateStatus(application.id!, 'rejected');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red, 
                              side: const BorderSide(color: Colors.red, width: 2),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateStatus(application.id!, 'accepted');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  if (application.status == 'review_pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showFinalizationDialog(application);
                        },
                        icon: const Icon(Icons.verified_rounded),
                        label: const Text('Verify & Complete Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Extra padding for bottom navigation bars
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Fatal Error in _showApplicantDetails: $e');
      if (mounted) {
        UIHelper.showError(context, e);
      }
    }
  }

  void _showFinalizationDialog(ApplicationModel application) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        title: Text('Finalize Task', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Has the student successfully completed the task to your satisfaction? By confirming, you verify their work and issue their final certificate.',
                style: GoogleFonts.manrope(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppTheme.textPrimary, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Write a brief endorsement for their certificate:',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Excellent work on the UI components...',
                  filled: true,
                  fillColor: AppTheme.getAdaptiveBackground(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                UIHelper.showError(context, 'Please provide an endorsement.');
                return;
              }
              Navigator.pop(context);
              await _dbService.finalizeApplication(application.id!, controller.text.trim());
              if (mounted) {
                UIHelper.showSuccess(context, 'Task finalized and certificate issued!');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm & Finalize'),
          ),
        ],
      ),
    );
  }

  void _showNewCVPreview(StudentProfileModel student) {
    CVPreviewModal.show(
      context,
      cvUrl: student.cvUrl,
      studentName: student.name,
      fileType: student.cvFileType,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCompletedTaskSnippet(ApplicationModel application) {
    return FutureBuilder<OpportunityModel?>(
      future: _dbService.getOpportunity(application.opportunityId),
      builder: (context, oppSnapshot) {
        final opp = oppSnapshot.data;
        return FutureBuilder<StartupProfileModel?>(
          future: opp != null ? _dbService.getStartupProfile(opp.startupId) : Future.value(null),
          builder: (context, startupSnapshot) {
            final startup = startupSnapshot.data;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getAdaptiveBackground(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          opp?.title ?? 'Completed Task',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                    ],
                  ),
                  Text(
                    startup?.companyName ?? 'Startup',
                    style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.getAdaptivePrimary(context), fontWeight: FontWeight.w600),
                  ),
                  if (application.endorsementLetter != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${application.endorsementLetter}"',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.getAdaptiveTextSecondary(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
        title: Text('Review Applicants', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
      ),
      body: StreamBuilder<List<ApplicationModel>>(
        stream: _dbService.getOpportunityApplications(widget.opportunityId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text('Error loading applicants', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                  if (snapshot.error.toString().contains('index'))
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'This usually means a Firebase index is missing. Check your browser console for a link to create it.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final applicantList = snapshot.data ?? [];

          // Handle deep-linking from notification
          if (widget.applicantId != null && !_hasDeepLinked && applicantList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasDeepLinked) {
                try {
                  final targetApp = applicantList.firstWhere(
                    (a) => a.id == widget.applicantId,
                  );
                  _hasDeepLinked = true;
                  _showApplicantDetails(targetApp);
                } catch (e) {
                  debugPrint('Deep-link applicant not found: ${widget.applicantId}');
                }
              }
            });
          }

          return Column(
            children: [
              StreamBuilder<OpportunityModel?>(
                stream: _dbService.getOpportunityStream(widget.opportunityId),
                builder: (context, oppSnapshot) {
                  final opportunity = oppSnapshot.data;
                  if (opportunity == null) return const SizedBox.shrink();
                  
                  final remaining = (opportunity.maxStudents - opportunity.filledSlots).clamp(0, 999);
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.getAdaptivePrimary(context).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.getAdaptivePrimary(context).withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: AppTheme.getAdaptivePrimary(context)),
                                const SizedBox(width: 8),
                                Text(
                                  'Task Details',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.getAdaptivePrimary(context),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: remaining > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${opportunity.filledSlots}/${opportunity.maxStudents} VACANCY',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: remaining > 0 ? Colors.orange[700] : Colors.green[700],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          opportunity.description,
                          style: GoogleFonts.manrope(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppTheme.textPrimary, height: 1.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(opportunity.duration, style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary)),
                            const SizedBox(width: 16),
                            Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(opportunity.workType ?? 'Remote', style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (applicantList.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text('No applicants yet.', style: GoogleFonts.manrope(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: applicantList.length,
                    itemBuilder: (context, index) {
                      final application = applicantList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          child: InkWell(
                            onTap: () => _showApplicantDetails(application),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.getAdaptivePrimary(context).withOpacity(0.1),
                                    child: Icon(Icons.person_rounded, color: AppTheme.getAdaptivePrimary(context)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: FutureBuilder<StudentProfileModel?>(
                                      future: _dbService.getStudentProfile(application.studentId),
                                      builder: (context, profileSnapshot) {
                                        if (profileSnapshot.connectionState == ConnectionState.waiting) {
                                          return Text('Loading...', style: GoogleFonts.manrope(color: Colors.grey, fontSize: 13));
                                        }
                                        final profileName = profileSnapshot.data?.name ?? 'Applicant';
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profileName,
                                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                                            ),
                                            Text(
                                              'Applied on ${application.createdAt.toLocal().toString().split(' ')[0]}',
                                              style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondary, fontSize: 13),
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: application.status == 'pending' 
                                          ? AppTheme.getAdaptiveBackground(context) 
                                          : application.status == 'declined'
                                              ? Colors.red.withOpacity(0.15)
                                              : application.status == 'active' || application.status == 'completed'
                                                  ? Colors.green.withOpacity(0.15)
                                                  : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      application.status.toUpperCase(),
                                      style: GoogleFonts.manrope(
                                        color: application.status == 'pending' 
                                            ? AppTheme.getAdaptiveTextSecondary(context) 
                                            : application.status == 'declined'
                                                ? Colors.red
                                                : application.status == 'active' || application.status == 'completed'
                                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.green[700])
                                                    : Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
