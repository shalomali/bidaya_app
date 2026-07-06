import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/application_model.dart';
import '../../../models/startup_profile_model.dart';
import '../../../models/notification_model.dart';
import '../../../core/theme.dart';
import '../../../core/ui_helper.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/notification_router.dart';
import '../../shared/screens/settings_screen.dart';

class StartupDashboardScreen extends StatefulWidget {
  const StartupDashboardScreen({super.key});

  @override
  State<StartupDashboardScreen> createState() => _StartupDashboardScreenState();
}

class _StartupDashboardScreenState extends State<StartupDashboardScreen> {
  int _selectedIndex = 0;
  DateTime? _lastPressedAt;

  Future<void> _deleteOpportunity(OpportunityModel opp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Opportunity', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${opp.title}"? This action cannot be undone and will also remove all associated applications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService().deleteOpportunity(opp.id!);
        if (mounted) {
          UIHelper.showSuccess(context, 'Opportunity deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          UIHelper.showError(context, e);
        }
      }
    }
  }

  Widget _buildCompanyHeader(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const SizedBox.shrink();
    
    final dbService = DatabaseService();

    return FutureBuilder<StartupProfileModel?>(
      future: dbService.getStartupProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28), // Expressive rounding
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.companyName ?? 'Your Startup',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          profile?.industry ?? 'Technology',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppTheme.getAdaptivePrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.goNamed('startupEditProfile'),
                    icon: Icon(Icons.edit_outlined, color: AppTheme.getAdaptivePrimary(context), size: 22),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildHeaderStat(Icons.rocket_launch_outlined, profile?.stage ?? 'Seed'),
                  const SizedBox(width: 16),
                  _buildHeaderStat(Icons.location_on_outlined, profile?.workType ?? 'Remote'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
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
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getAdaptiveTextColor(context)),
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
                            Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.getAdaptiveIconColor(context)),
                            const SizedBox(height: 16),
                            Text(
                              'Your notifications will appear here',
                              style: GoogleFonts.manrope(
                                color: AppTheme.getAdaptiveTextColor(context).withOpacity(0.6), 
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Stay tuned for new applicants and task updates!',
                              style: GoogleFonts.manrope(color: AppTheme.getAdaptiveTextColor(context).withOpacity(0.5), fontSize: 13),
                            ),
                            const SizedBox(height: 100), // Push slightly up from dead center
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
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
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: n.isRead ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  n.type == 'application_received' ? Icons.mail_outline : (n.type == 'task_completed' ? Icons.check_circle_outline : Icons.info_outline),
                                  size: 20,
                                  color: n.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(n.title, style: GoogleFonts.manrope(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                              subtitle: Text(n.message, style: GoogleFonts.manrope(fontSize: 12)),
                              trailing: Text(
                                DateFormat('MMM d, h:mm a').format(n.createdAt),
                                style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey),
                              ),
                              onTap: () {
                                if (!n.isRead && n.id != null) {
                                  DatabaseService().markNotificationAsRead(n.id!);
                                }
                                Navigator.pop(context); // Close notifications sheet
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


  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    if (authService.userModel == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = authService.userModel!;
    final dbService = DatabaseService();

    // Defensive fallback: If somehow reached without profile, redirect
    if (authService.isInitialized && !authService.hasProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/startup/setup');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Widget dashboardView = StreamBuilder<List<OpportunityModel>>(
      stream: dbService.getStartupOpportunities(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final opportunities = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            // Sync opportunity capacity automatically on refresh
            for (var opp in opportunities) {
              if (opp.id != null) {
                await dbService.syncOpportunityCapacity(opp.id!);
              }
            }
            if (mounted) setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildCompanyHeader(context),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Posted Opportunities',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.getAdaptivePrimary(context))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (opportunities.isEmpty)
                UIHelper.buildEmptyState(
                  context: context,
                  icon: Icons.post_add_rounded,
                  title: 'No opportunities yet',
                  message: 'Start by posting your first task to match with talented students!',
                  actionLabel: 'Post Task Now',
                  onAction: () => context.goNamed('startupPostOpportunity'),
                )
              else
                ...opportunities.map((opp) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  child: InkWell(
                    onTap: () {
                      if (opp.id != null) {
                        context.goNamed('startupReviewApplicants', pathParameters: {'id': opp.id!});
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opp.title,
                                  style: GoogleFonts.manrope(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      opp.duration,
                                      style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(width: 12),
                                    CircleAvatar(radius: 2, backgroundColor: AppTheme.getAdaptiveIconColor(context)),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${opp.filledSlots}/${opp.maxStudents} Filled',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: opp.filledSlots >= opp.maxStudents ? Colors.green : AppTheme.getAdaptivePrimary(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    CircleAvatar(radius: 2, backgroundColor: AppTheme.getAdaptiveIconColor(context)),
                                    const SizedBox(width: 12),
                                    StreamBuilder<List<ApplicationModel>>(
                                      stream: dbService.getOpportunityApplications(opp.id!),
                                      builder: (context, appSnapshot) {
                                        if (appSnapshot.hasError) {
                                          return Tooltip(
                                            message: 'Query error (check console/indexes): ${appSnapshot.error}',
                                            child: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                                          );
                                        }
                                        final count = appSnapshot.data?.length ?? 0;
                                        return Text(
                                          '$count Applicants',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: AppTheme.getAdaptivePrimary(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                                  StreamBuilder<List<ApplicationModel>>(
                                    stream: dbService.getOpportunityApplications(opp.id!),
                                    builder: (context, appSnapshot) {
                                      if (appSnapshot.hasError) return const SizedBox.shrink();
                                      final apps = appSnapshot.data ?? [];
                                      final hasReviewPending = apps.any((a) => a.status == 'review_pending');
                                      
                                      if (hasReviewPending && opp.status != 'completed') {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.error_outline_rounded, size: 12, color: Colors.blue),
                                              const SizedBox(width: 4),
                                              Text(
                                                'VERIFY TASK',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.blue,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (opp.status == 'completed') {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.verified_rounded, size: 12, color: Colors.green),
                                              const SizedBox(width: 4),
                                              Text(
                                                'COMPLETED',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.green,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                              const SizedBox(height: 12),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: AppTheme.getAdaptiveIconColor(context), size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    context.pushNamed('startupPostOpportunity', extra: opp);
                                  } else if (value == 'delete') {
                                    _deleteOpportunity(opp);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18, color: AppTheme.getAdaptiveTextColor(context)),
                                        const SizedBox(width: 8),
                                        Text('Edit', style: GoogleFonts.manrope()),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        const SizedBox(width: 8),
                                        Text('Delete', style: GoogleFonts.manrope(color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Icon(Icons.chevron_right_rounded, color: AppTheme.getAdaptiveIconColor(context)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          ],
        ), // ListView
      );   // RefreshIndicator
    },     // builder
  );       // StreamBuilder

  final Widget settingsView = const SettingsScreen();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
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
        body: _selectedIndex == 0 ? dashboardView : settingsView,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.getAdaptiveSurface(context),
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: AppTheme.getAdaptivePrimary(context),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
        floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
          onPressed: () => context.goNamed('startupPostOpportunity'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          icon: const Icon(Icons.add_rounded),
          label: Text('Post Opportunity', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13)),
          elevation: 0, // M3 uses tonal elevation
          shape: const StadiumBorder(),
        ) : null,
      ),
    );
  }
}
