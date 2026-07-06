import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/database_service.dart';
import '../../../models/application_model.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/student_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import '../../shared/widgets/certificate_widget.dart';
import '../../../models/startup_profile_model.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/certificate_helper.dart';

class StudentApplicationsView extends StatelessWidget {
  const StudentApplicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const Center(child: CircularProgressIndicator());

    final dbService = DatabaseService();

    void showPendingDialog(BuildContext context, String status) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.getAdaptiveSurface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            status == 'review_pending' ? 'Task Review' : 'Application Pending',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.getAdaptivePrimary(context)),
          ),
          content: Text(
            status == 'review_pending' 
                ? 'Your work is currently being reviewed by the startup. You will be notified once they make a decision.'
                : 'Your application is currently being reviewed by the startup. You will be notified once they make a decision.',
            style: GoogleFonts.manrope(height: 1.5, color: AppTheme.getAdaptiveTextSecondary(context)),
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

    void showAgreementDialog(BuildContext context, ApplicationModel app) {
      bool isSubmitting = false;
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.getAdaptiveSurface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Mutual Agreement',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.getAdaptivePrimary(context)),
              ),
              content: SingleChildScrollView(
                child: Text(
                  'The startup has accepted your application! By accepting this agreement, you commit to completing the task as described. Your contact information will be shared with the startup, and the hidden confidential details will be revealed to you.',
                  style: GoogleFonts.manrope(height: 1.5, color: AppTheme.getAdaptiveTextSecondary(context)),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () async {
                    setDialogState(() => isSubmitting = true);
                    try {
                      await dbService.declineApplication(app.id!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        UIHelper.showSuccess(context, 'Offer declined.');
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (context.mounted) UIHelper.showError(context, e);
                    }
                  },
                  child: Text('Decline', style: GoogleFonts.manrope(color: isSubmitting ? Colors.grey : Colors.red, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setDialogState(() => isSubmitting = true);
                    try {
                      await dbService.acceptAgreement(app.id!);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (context.mounted) UIHelper.showError(context, e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Accept'),
                ),
              ],
            );
          }
        ),
      );
    }

    void showActiveTaskDetails(BuildContext context, ApplicationModel app) {
       bool isSubmitting = false;
       showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        // surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.rocket_launch, size: 20, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ACTIVE TASK',
                          style: GoogleFonts.manrope(color: Colors.green[400], fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Confidential Details',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.getAdaptiveTextPrimary(context)),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<OpportunityModel?>(
                      future: dbService.getOpportunity(app.opportunityId),
                      builder: (context, oppSnapshot) {
                        if (oppSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: LinearProgressIndicator());
                        }
                        final opp = oppSnapshot.data!;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.getAdaptiveBackground(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                          child: Text(
                            opp.hiddenDetails.isNotEmpty ? opp.hiddenDetails : 'No confidential details provided.',
                            style: GoogleFonts.manrope(height: 1.6, color: AppTheme.getAdaptiveTextSecondary(context)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await dbService.markTaskAsCompletedByStudent(app.id!);
                            if (context.mounted) {
                              Navigator.pop(context);
                              UIHelper.showSuccess(context, 'Task marked as complete. Pending startup review.');
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) UIHelper.showError(context, e);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.getAdaptivePrimary(context)),
                        child: isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Mark as Completed'),
                      ),
                    ),
                    ],
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

    void showDeclinedDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Offer Declined',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          content: SingleChildScrollView(
            child: Text(
              'You have declined this opportunity. If this was a mistake, please reach out to the startup directly or look for other amazing opportunities on Bidaya!',
              style: GoogleFonts.manrope(height: 1.5, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
          ],
        ),
      );
    }

    void showCertificateDialog(BuildContext context, ApplicationModel app) {
      final GlobalKey certificateKey = GlobalKey();
      
      showDialog(
        context: context,
        builder: (context) => FutureBuilder<OpportunityModel?>(
          future: dbService.getOpportunity(app.opportunityId),
          builder: (context, oppSnapshot) {
            if (!oppSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final opp = oppSnapshot.data!;

            return FutureBuilder<StudentProfileModel?>(
              future: dbService.getStudentProfile(app.studentId),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final student = studentSnapshot.data!;

                return FutureBuilder<StartupProfileModel?>(
                  future: dbService.getStartupProfile(opp.startupId),
                  builder: (context, startupSnapshot) {
                    final startupName = startupSnapshot.data?.companyName ?? 'Bidaya Partner';
                    return AlertDialog(
                      backgroundColor: AppTheme.getAdaptiveSurface(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: EdgeInsets.zero,
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: CertificateWidget(
                                studentName: student.name,
                                taskTitle: opp.title,
                                date: DateFormat('MMMM dd, yyyy').format(app.createdAt),
                                startupName: startupName,
                                endorsement: app.endorsementLetter,
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
                                          fileName: 'Bidaya_Certificate_${opp.title}',
                                        );
                                      },
                                      icon: const Icon(Icons.download_rounded, size: 18),
                                      label: const Text('Download'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.getAdaptivePrimary(context),
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
                    );
                  }
                );
              },
            );
          },
        ),
      );
    }

    return StreamBuilder<List<ApplicationModel>>(
      stream: dbService.getStudentApplications(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return UIHelper.buildEmptyState(
            context: context,
            icon: Icons.assignment_outlined,
            title: 'No applications yet',
            message: 'You haven\'t applied to any tasks yet. Explore available opportunities to start your journey!',
            actionLabel: 'Browse Tasks',
            onAction: () {
              // Usually handled by parent dashboard, but we can try to pop or notify
              // For simplicity in this view, we'll suggest browsing.
              // In the actual app, this should probably switch the tab.
              // Since this is a sub-view, we'll rely on the user to switch or use a callback if available.
              // Actually, we can use a callback if passed in.
            },
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding for Nav Bar
          itemCount: applications.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Applications',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              );
            }
            final app = applications[index - 1];
            final status = app.status;
            
            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.hourglass_empty;
            
            if (status == 'accepted') {
              statusColor = Colors.orange;
              statusIcon = Icons.handshake;
            } else if (status == 'active') {
              statusColor = Colors.green;
              statusIcon = Icons.play_arrow_rounded;
            } else if (status == 'rejected') {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
            } else if (status == 'declined') {
              statusColor = Colors.grey;
              statusIcon = Icons.do_not_disturb_on_outlined;
            } else if (status == 'review_pending') {
              statusColor = Colors.blue;
              statusIcon = Icons.access_time_filled;
            } else if (status == 'completed') {
              statusColor = AppTheme.getAdaptivePrimary(context);
              statusIcon = Icons.check_circle;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Card(
                child: InkWell(
                  onTap: () {
                    if (status == 'pending') {
                      showPendingDialog(context, 'pending');
                    } else if (status == 'accepted') showAgreementDialog(context, app);
                    else if (status == 'active') showActiveTaskDetails(context, app);
                    else if (status == 'review_pending') showPendingDialog(context, 'review_pending'); // Reuse pending dialog or create new one
                    else if (status == 'completed') showCertificateDialog(context, app);
                    else if (status == 'declined') showDeclinedDialog(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<OpportunityModel?>(
                          future: dbService.getOpportunity(app.opportunityId),
                          builder: (context, oppSnapshot) {
                            return FutureBuilder<StartupProfileModel?>(
                              future: dbService.getStartupProfile(app.startupId),
                              builder: (context, startupSnapshot) {
                                final oppTitle = oppSnapshot.data?.title ?? 'Task';
                                final companyName = startupSnapshot.data?.companyName ?? 'Startup';
                                
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$oppTitle - $companyName',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16, 
                                          color: AppTheme.getAdaptivePrimary(context),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, size: 14, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            status.toUpperCase(),
                                            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            );
                          }
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view details or actions',
                          style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.getAdaptiveTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
