import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class CertificateWidget extends StatelessWidget {
  final String studentName;
  final String taskTitle;
  final String date;
  final String startupName;
  final String? endorsement;
  final GlobalKey? boundaryKey;

  const CertificateWidget({
    super.key,
    required this.studentName,
    required this.taskTitle,
    required this.date,
    required this.startupName,
    this.endorsement,
    this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: AspectRatio(
        aspectRatio: 1.414, // A4 Landscape ratio
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 1000, // Fixed logical width for internal scaling
            height: 1000 / 1.414,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5), // Thin outer gray border
            ),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  // Top Logo
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 80),
                  ),
                  const SizedBox(height: 30),
                  
                  // Title
                  Text(
                    'CERTIFICATE OF APPRECIATION',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Proudly presented to',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Student Name with Blue Underline
                  Column(
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.dancingScript(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 300,
                        height: 2,
                        color: AppTheme.primary.withOpacity(0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        Text(
                          'For outstanding dedication and excellence in completing the professional task',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TASK: $taskTitle From $startupName company',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Bottom Section: Signature & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Signature Block
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/signature.jpg',
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 60, width: 120),
                          ),
                          Container(
                            width: 150,
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hermela Amha',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Bidaya Project Manager',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      
                      // Date Block
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date: $date',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verified Digital Outcome',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
