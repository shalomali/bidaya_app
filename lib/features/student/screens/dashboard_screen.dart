import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/student_profile_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/application_model.dart';
import '../../../models/startup_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import 'applications_view.dart';
import 'browse_opportunities_view.dart';
import 'completed_tasks_view.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/widgets/certificate_widget.dart';
import '../../../core/utils/notification_router.dart';
import '../../../core/ui_helper.dart';
import 'package:intl/intl.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String? appId;
  const StudentDashboardScreen({super.key, this.appId});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  final bool _hasDeepLinked = false;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    if (widget.appId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLinkById(widget.appId!);
      });
    }
  }

  Future<void> _handleDeepLinkById(String id) async {
    final dbService = DatabaseService();
    // 1. Try fetching as Application ID
    var app = await dbService.getApplication(id);
    
    // 2. Fallback: If not found, try fetching as Opportunity ID (for old notifications)
    if (app == null) {
      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid != null) {
        final apps = await dbService.getApplicationsByOpportunityAndStudent(id, userUid);
        if (apps.isNotEmpty) app = apps.first;
      }
    }

    if (app != null && mounted) {
      _showCertificateDialog(context, app);
    }
  }

  void _showNotifications(BuildContext context, List<NotificationModel> notifications) {
    if (notifications.any((n) => !n.isRead)) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseService().markAllNotificationsAsRead(user.uid);
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getAdaptiveSurface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Notifications',
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[100]),
                            const SizedBox(height: 16),
                            Text(
                              'Your notifications will appear here',
                              style: GoogleFonts.manrope(
                                color: Colors.grey[400], 
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Stay tuned for updates on your applications!',
                              style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 13),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return Dismissible(
                            key: Key(n.id ?? index.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.redAccent,
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              if (n.id != null) {
                                DatabaseService().deleteNotification(n.id!);
                              }
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: n.isRead ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]) : AppTheme.primary.withOpacity(0.1),
                                child: Icon(
                                  n.type == 'status_update' ? Icons.notification_important : (n.type == 'task_completed' ? Icons.emoji_events : Icons.info_outline),
                                  size: 20,
                                  color: n.isRead ? Colors.grey : AppTheme.primary,
                                ),
                              ),
                              title: Text(n.title, style: GoogleFonts.manrope(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                              subtitle: Text(n.message, style: GoogleFonts.manrope(fontSize: 12)),
                              onTap: () async {
                                DatabaseService().markNotificationAsRead(n.id!);
                                Navigator.pop(context);
                                NotificationRouter.navigate(context, n);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCertificateDialog(BuildContext context, ApplicationModel app) {
    final GlobalKey certificateKey = GlobalKey();
    final dbService = DatabaseService();
    
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
                                      UIHelper.showSuccess(context, 'Certificate generation coming soon!');
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

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.userModel;
    final dbService = DatabaseService();

    // Defensive fallback: If somehow reached without profile, redirect
    if (authService.isInitialized && !authService.hasProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student/setup');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Widget matchesView = const BrowseOpportunitiesView();

    final Widget bookmarksView = user == null
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<StudentProfileModel?>(
            stream: dbService.getStudentProfileStream(user.uid),
            builder: (context, profileSnapshot) {
              final studentProfile = profileSnapshot.data;
              if (studentProfile == null) return const Center(child: CircularProgressIndicator());

              return StreamBuilder<List<OpportunityModel>>(
                stream: dbService.getOpportunities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allOpportunities = snapshot.data ?? [];
                  final bookmarkedOpps = allOpportunities
                      .where((opp) => studentProfile.bookmarks.contains(opp.id))
                      .toList();

                  if (bookmarkedOpps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save interesting tasks for later!',
                            style: GoogleFonts.manrope(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: bookmarkedOpps.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            'Bookmarked Tasks',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        );
                      }
                      
                      final opp = bookmarkedOpps[index - 1];
                      // Note: Profile Header now handles its own matching UI 
                      // in BrowseOpportunitiesView, but here we can keep a simpler card
                      return _buildSimpleBookmarkCard(context, opp, studentProfile);
                    },
                  );
                },
              );
            },
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          final now = DateTime.now();
          if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tap back again to exit Bidaya',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                width: 250,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.transparent,
              BlendMode.srcATop,
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: false,
          actions: [
            if (user != null)
              StreamBuilder<List<NotificationModel>>(
                stream: dbService.getNotifications(user.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () => _showNotifications(context, snapshot.data ?? []),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => context.read<AuthService>().signOut(),
            )
          ],
        ),
        body: _currentIndex == 0 
            ? matchesView 
            : (_currentIndex == 1 
                ? const StudentApplicationsView() 
                : (_currentIndex == 2 
                    ? bookmarksView
                    : (_currentIndex == 3 
                        ? StudentCompletedTasksView(
                            studentId: user?.uid ?? '',
                            onViewCertificate: (app) => _showCertificateDialog(context, app),
                          ) 
                        : const SettingsScreen()))),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.getAdaptiveSurface(context),
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppTheme.getAdaptivePrimary(context),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_turned_in_outlined),
                activeIcon: Icon(Icons.assignment_turned_in_rounded),
                label: 'Applications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_outline_rounded),
                activeIcon: Icon(Icons.bookmark_rounded),
                label: 'Bookmarks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fact_check_outlined),
                activeIcon: Icon(Icons.fact_check_rounded),
                label: 'Completed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleBookmarkCard(BuildContext context, OpportunityModel opp, StudentProfileModel? studentProfile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        child: InkWell(
          onTap: () => context.goNamed('studentOpportunityDetails', pathParameters: {'id': opp.id ?? ''}),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getAdaptiveBackground(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        opp.workType ?? 'Remote',
                        style: GoogleFonts.manrope(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark, color: AppTheme.primary, size: 20),
                      onPressed: () {
                        if (studentProfile != null && opp.id != null) {
                          DatabaseService().toggleBookmark(studentProfile.uid, opp.id!);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  opp.title,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(opp.duration, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
