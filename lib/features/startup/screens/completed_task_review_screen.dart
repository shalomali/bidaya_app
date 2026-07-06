import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/application_model.dart';
import '../../../models/student_profile_model.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/theme.dart';
import '../../../core/ui_helper.dart';
import '../../shared/widgets/certificate_widget.dart';
import 'package:intl/intl.dart';

class CompletedTaskReviewScreen extends StatefulWidget {
  final String opportunityId;

  const CompletedTaskReviewScreen({super.key, required this.opportunityId});

  @override
  State<CompletedTaskReviewScreen> createState() => _CompletedTaskReviewScreenState();
}

class _CompletedTaskReviewScreenState extends State<CompletedTaskReviewScreen> {
  final _feedbackController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  
  OpportunityModel? _opportunity;
  ApplicationModel? _application;
  StudentProfileModel? _student;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    try {
      final opp = await _dbService.getOpportunity(widget.opportunityId);
      if (opp == null) return;

      final apps = await _dbService.getOpportunityApplications(widget.opportunityId).first;
      // Search for applications that are either currently in review, active, or already completed
      final app = apps.firstWhere(
        (a) => a.status == 'review_pending' || a.status == 'active' || a.status == 'completed',
        orElse: () => throw 'No active or pending application found for this task.'
      );

      final student = await _dbService.getStudentProfile(app.studentId);

      if (mounted) {
        setState(() {
          _opportunity = opp;
          _application = app;
          _student = student;
          _isLoading = false;
          if (app.status == 'completed' && app.endorsementLetter != null) {
            _feedbackController.text = app.endorsementLetter!;
          }
        });
      }
    } catch (e) {
      debugPrint('Error in _fetchData: $e');
      if (mounted) {
        UIHelper.showError(context, 'Could not load task details.');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateCertificate() async {
    if (_opportunity == null || _application == null) return;

    final feedback = _feedbackController.text.trim();
    final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<StartupProfileModel?>(
          future: _dbService.getStartupProfile(_opportunity!.startupId),
          builder: (context, startupSnapshot) {
            final startupName = startupSnapshot.data?.companyName ?? 'Bidaya Partner';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Verification Confirmation', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'By clicking "Confirm & Send", you verify that the student has completed the task to your satisfaction.',
                    style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.getAdaptiveSurface(context), // Changed from AppTheme.background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CertificateWidget(
                      studentName: _student?.name ?? 'Student',
                      taskTitle: _opportunity!.title,
                      date: dateStr,
                      startupName: startupName,
                      endorsement: feedback,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context)))), // Adaptive color for Cancel
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    setState(() => _isSubmitting = true);
                    try {
                      await _dbService.finalizeApplication(_application!.id!, feedback);
                      await _dbService.updateOpportunityStatus(_opportunity!.id!, 'completed');
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint('Error finalizing application: $e');
                      if (context.mounted) {
                        UIHelper.showError(context, 'Error finalizing application: $e');
                      }
                      setState(() => _isSubmitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Issue Certificate'),
                ),
              ],
            );
          }
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getAdaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
        title: Text('Task Review', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.getAdaptivePrimary(context).withOpacity(0.1), // Adaptive color
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.help_outline_rounded, color: AppTheme.getAdaptivePrimary(context), size: 56), // Adaptive color
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Did the student complete this task?',
                    style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_student?.name ?? 'Student'} has marked this task as finished and is requesting verification.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 48),
                if (_application?.status == 'completed') ...[
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Verification Complete!',
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have successfully verified this task and issued the certificate.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.getAdaptiveTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text('Return to Dashboard', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Endorsement Letter',
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If yes, provide a brief testimonial that will be visible on the student\'s profile and certificate.',
                    style: GoogleFonts.manrope(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'e.g. Excellent work on the UI components. Highly recommended for Flutter development...',
                      hintStyle: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary, fontSize: 14), // Adaptive hint color
                      filled: true,
                      fillColor: AppTheme.getAdaptiveSurface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    style: GoogleFonts.manrope(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _generateCertificate,
                      icon: const Icon(Icons.verified_rounded, color: Colors.white),
                      label: Text('Yes, Verify & Issue Certificate', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'No, not completed yet',
                        style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
