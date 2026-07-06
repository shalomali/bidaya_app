import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/theme.dart';
import '../../../utils/url_launcher.dart';

class StartupProfileViewScreen extends StatelessWidget {
  final StartupProfileModel profile;

  const StartupProfileViewScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getAdaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getAdaptiveSurface(context),
        foregroundColor: AppTheme.getAdaptiveTextPrimary(context),
        title: Text('Company Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary.withOpacity(0.05),
                    child: Text(
                      profile.companyName[0].toUpperCase(),
                      style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.companyName,
                    style: GoogleFonts.manrope(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.getAdaptiveTextPrimary(context),
                    ),
                  ),
                  if (profile.industry != null)
                    Text(
                      profile.industry!,
                      style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.getAdaptiveTextSecondary(context)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              context,
              'About the Company',
              Text(
                profile.description, 
                style: GoogleFonts.manrope(
                  height: 1.6, 
                  color: AppTheme.getAdaptiveTextPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Company Details',
              Column(
                children: [
                  if (profile.stage != null)
                    _buildDetailItem(context, Icons.rocket_launch_outlined, 'Stage', profile.stage!),
                  if (profile.workType != null)
                    _buildDetailItem(context, Icons.location_on_outlined, 'Work Type', profile.workType!),
                  if (profile.website != null && profile.website!.isNotEmpty)
                    _buildLinkItem(context, Icons.language_rounded, 'Website', profile.website!),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 12, 
            fontWeight: FontWeight.w900, 
            color: AppTheme.getAdaptiveTextSecondary(context), 
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getAdaptiveSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: AppTheme.getAdaptiveTextSecondary(context),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: AppTheme.getAdaptiveTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, IconData icon, String label, String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: AppTheme.getAdaptiveTextPrimary(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () => ExternalLauncher.open(url),
            child: const Text('Visit'),
          ),
        ],
      ),
    );
  }
}
