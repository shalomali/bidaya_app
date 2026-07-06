import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../utils/web_helper.dart';
import '../../../core/theme.dart';
import '../../../utils/url_launcher.dart';

class CVPreviewModal extends StatefulWidget {
  final String cvUrl;
  final String studentName;
  final String? fileType; // 'pdf' or 'image'

  const CVPreviewModal({
    super.key,
    required this.cvUrl,
    required this.studentName,
    this.fileType,
  });

  static void show(BuildContext context, {
    required String cvUrl,
    required String studentName,
    String? fileType,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CV Preview',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return CVPreviewModal(
          cvUrl: cvUrl,
          studentName: studentName,
          fileType: fileType,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CVPreviewModal> createState() => _CVPreviewModalState();
}

class _CVPreviewModalState extends State<CVPreviewModal> {
  bool _isLoading = true;
  bool _hasError = false;
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'pdf-viewer-${widget.cvUrl.hashCode}';
    
    if (kIsWeb && (widget.fileType == 'pdf' || widget.fileType == null)) {
      // Register the iframe for web
      registerWebView(_viewId, widget.cvUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.fileType?.toLowerCase() ?? '';
    final bool isImage = type == 'image' || 
                         type == 'jpg' || 
                         type == 'jpeg' || 
                         type == 'png' || 
                         type == 'webp';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context),
                
                // Content
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    child: Stack(
                      children: [
                        if (isImage)
                          _buildImageViewer()
                        else
                          _buildPdfViewer(),
                        
                        if (_isLoading && isImage)
                          const Center(child: CircularProgressIndicator()),
                        
                        if (_hasError)
                          _buildErrorFallback(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.studentName,
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'CV Preview',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ExternalLauncher.open(widget.cvUrl),
            icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
            tooltip: 'Download CV',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.cvUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return child;
            }
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hasError = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    } else {
      return SfPdfViewer.network(
        widget.cvUrl,
        onDocumentLoadFailed: (details) {
          if (mounted) setState(() => _hasError = true);
        },
        onDocumentLoaded: (details) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    }
  }

  Widget _buildErrorFallback({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'We couldn\'t load the preview. You can still download the CV to view it.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ExternalLauncher.open(widget.cvUrl),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download Instead'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
