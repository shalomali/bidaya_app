import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../models/application_model.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';

class StudentCompletedTasksView extends StatefulWidget {
  final String studentId;
  final Function(ApplicationModel)? onViewCertificate;

  const StudentCompletedTasksView({
    super.key, 
    required this.studentId,
    this.onViewCertificate,
  });

  @override
  State<StudentCompletedTasksView> createState() => _StudentCompletedTasksViewState();
}

class _StudentCompletedTasksViewState extends State<StudentCompletedTasksView> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: _dbService.getStudentCompletedApplications(widget.studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return UIHelper.buildEmptyState(
            context: context,
            icon: Icons.assignment_turned_in_outlined,
            title: 'No completed tasks yet',
            message: 'Finish your active tasks to build your profile and earn endorsements!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: applications.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Completed Tasks',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              );
            }
            return _buildCompletedTaskCard(applications[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildCompletedTaskCard(ApplicationModel application) {
    return FutureBuilder<OpportunityModel?>(
      future: _dbService.getOpportunity(application.opportunityId),
      builder: (context, oppSnapshot) {
        final opportunity = oppSnapshot.data;
        
        return FutureBuilder<StartupProfileModel?>(
          future: opportunity != null ? _dbService.getStartupProfile(opportunity.startupId) : Future.value(null),
          builder: (context, startupSnapshot) {
            final startup = startupSnapshot.data;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  opportunity?.title ?? 'Completed Task',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.getAdaptiveTextPrimary(context),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'COMPLETED',
                                  style: GoogleFonts.manrope(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            startup?.companyName ?? 'Startup',
                            style: GoogleFonts.manrope(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_quote_rounded, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'STARTUP ENDORSEMENT',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                        color: AppTheme.getAdaptiveTextSecondary(context).withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  application.endorsementLetter ?? 'No endorsement provided.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.getAdaptiveTextPrimary(context).withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: AppTheme.getAdaptiveBackground(context).withOpacity(0.5),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.getAdaptiveTextSecondary(context)),
                          const SizedBox(width: 8),
                          Text(
                            'Completed on ${DateFormat('MMM dd, yyyy').format(application.createdAt)}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.getAdaptiveTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onViewCertificate != null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onViewCertificate!(application),
                            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                            label: const Text('Access Certificate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
