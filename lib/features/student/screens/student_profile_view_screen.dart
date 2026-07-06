import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_profile_model.dart';
import '../../../core/theme.dart';
import '../../../utils/url_launcher.dart';
import '../../shared/widgets/cv_preview_modal.dart';

class StudentProfileViewScreen extends StatelessWidget {
  final StudentProfileModel profile;

  const StudentProfileViewScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Student Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
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
                      profile.name[0].toUpperCase(),
                      style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  Text(
                    '${profile.major} @ ${profile.university}',
                    style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'About Me',
              Text(profile.bio ?? 'No bio provided.', style: GoogleFonts.manrope(height: 1.6, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Professional Links',
              Column(
                children: [
                  _buildLinkItem(context, Icons.link_rounded, 'Portfolio', profile.portfolioUrl),
                  const SizedBox(height: 12),
                  _buildLinkItem(context, Icons.description_outlined, 'Academic CV', profile.cvUrl, isCV: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Skills & Proficiency',
              Column(
                children: profile.skills.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                          Text('${e.value.round()}%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: e.value / 100,
                          minHeight: 8,
                          backgroundColor: AppTheme.primary.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Contact Information',
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(profile.email, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildLinkItem(BuildContext context, IconData icon, String label, String? url, {bool isCV = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
          if (url != null && url.isNotEmpty)
            TextButton(
              onPressed: () {
                if (isCV) {
                  CVPreviewModal.show(
                    context,
                    cvUrl: url,
                    studentName: profile.name,
                    fileType: profile.cvFileType,
                  );
                } else {
                  ExternalLauncher.open(url);
                }
              },
              child: const Text('View'),
            )
          else
            Text('Not provided', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
