import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/shared/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/student/screens/profile_setup_screen.dart';
import '../features/student/screens/dashboard_screen.dart';
import '../features/student/screens/opportunity_details_screen.dart';
import '../features/student/screens/edit_profile_screen.dart';
import '../features/startup/screens/profile_setup_screen.dart';
import '../features/startup/screens/dashboard_screen.dart';
import '../features/startup/screens/post_opportunity_screen.dart';
import '../features/startup/screens/applicant_review_screen.dart';
import '../features/startup/screens/completed_task_review_screen.dart';
import '../features/startup/screens/edit_profile_screen.dart';
import '../features/startup/screens/startup_profile_view_screen.dart';
import '../features/shared/screens/settings_screen.dart';
import '../models/opportunity_model.dart';
import '../models/startup_profile_model.dart';
import '../services/database_service.dart';

import '../services/auth_service.dart';
import '../core/input_sanitizer.dart';

class AppRouter {
  // ... (previous paths)
  static const String splashPath = '/';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String roleSelectionPath = '/role-selection';
  
  static const String studentDashboardPath = '/student';
  static const String studentProfileSetupPath = '/student/setup';
  
  static const String startupDashboardPath = '/startup';
  static const String startupProfileSetupPath = '/startup/setup';

  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: splashPath,
      refreshListenable: authService,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: splashPath,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: loginPath,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: registerPath,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: roleSelectionPath,
          name: 'roleSelection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        // Legacy/Notification Redirects
        GoRoute(
          path: '/opportunities',
          redirect: (context, state) => '/student',
        ),
        GoRoute(
          path: '/opportunities/:id',
          redirect: (context, state) {
            final id = state.pathParameters['id'];
            return '/student/opportunity/$id';
          },
        ),
        GoRoute(
          path: studentDashboardPath,
          name: 'studentDashboard',
          builder: (context, state) {
            final appId = state.uri.queryParameters['appId'];
            return StudentDashboardScreen(
              appId: InputSanitizer.isValidUid(appId) ? appId : null,
            );
          },
          routes: [
            GoRoute(
              path: 'setup',
              name: 'studentSetup',
              builder: (context, state) => const StudentSetupScreen(),
            ),
            GoRoute(
              path: 'opportunity/:id',
              name: 'studentOpportunityDetails',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return OpportunityDetailsScreen(
                  opportunityId: InputSanitizer.isValidUid(id) ? id! : '',
                );
              },
            ),
            GoRoute(
              path: 'edit-profile',
              name: 'studentEditProfile',
              builder: (context, state) => const EditStudentProfileScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: 'studentSettings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'startup-profile/:id',
              name: 'studentStartupProfile',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return FutureBuilder<StartupProfileModel?>(
                  future: DatabaseService().getStartupProfile(id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Scaffold(body: Center(child: Text('Company profile not found.')));
                    }
                    return StartupProfileViewScreen(profile: snapshot.data!);
                  },
                );
              },
            ),
          ]
        ),
        GoRoute(
          path: startupDashboardPath,
          name: 'startupDashboard',
          builder: (context, state) => const StartupDashboardScreen(),
          routes: [
            GoRoute(
              path: 'setup',
              name: 'startupSetup',
              builder: (context, state) => const StartupSetupScreen(),
            ),
            GoRoute(
              path: 'post',
              name: 'startupPostOpportunity',
              builder: (context, state) => PostOpportunityScreen(
                opportunity: state.extra as OpportunityModel?,
              ),
            ),
            GoRoute(
              path: 'review/:id',
              name: 'startupReviewApplicants',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                final appId = state.uri.queryParameters['appId'];
                return ApplicantReviewScreen(
                  opportunityId: InputSanitizer.isValidUid(id) ? id! : '',
                  applicantId: InputSanitizer.isValidUid(appId) ? appId : null,
                );
              },
            ),
            GoRoute(
              path: 'complete/:id',
              name: 'startupCompleteTask',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return CompletedTaskReviewScreen(
                  opportunityId: InputSanitizer.isValidUid(id) ? id! : '',
                );
              },
            ),
            GoRoute(
              path: 'edit-profile',
              name: 'startupEditProfile',
              builder: (context, state) => const EditStartupProfileScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: 'startupSettings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]
        ),
      ],
      redirect: (context, state) {
        // IMPORTANT: While the app is still fetching the initial auth state,
        // we stay on the current path (which starts at splashPath).
        if (!authService.isInitialized) return null;

        final loggedIn = authService.userModel != null;
        final isAuthPath = state.matchedLocation == loginPath || state.matchedLocation == registerPath || state.matchedLocation == splashPath;

        if (!loggedIn) {
          // Allow access to auth paths and splash screen
          return isAuthPath ? null : loginPath;
        }

        if (isAuthPath) {
          // If logged in but on splash or auth paths, go to dashboard
          // unless we are specifically on the splash screen which has its own timer
          if (state.matchedLocation == splashPath) return null;
          
          final role = authService.userModel?.role;
          if (role == null || role.isEmpty) return roleSelectionPath;
          
          if (!authService.hasProfile) {
            if (role == 'student') return studentProfileSetupPath;
            if (role == 'startup') return startupProfileSetupPath;
            return roleSelectionPath; // Fallback if role is invalid
          }
          
          if (role == 'student') return studentDashboardPath;
          if (role == 'startup') return startupDashboardPath;
          return roleSelectionPath; // Fallback
        }

        // If logged in and on a dashboard or sub-route WITHOUT a profile, force redirect to setup
        final hasProfile = authService.hasProfile;
        final onDashboardOrSub = state.matchedLocation.startsWith(studentDashboardPath) || 
                                 state.matchedLocation.startsWith(startupDashboardPath);
        
        if (!hasProfile && onDashboardOrSub) {
          final role = authService.userModel?.role;
          final currentIsSetup = state.matchedLocation == studentProfileSetupPath || 
                                 state.matchedLocation == startupProfileSetupPath;
          
          if (!currentIsSetup) {
            debugPrint('Router: No profile detected on dashboard path, redirecting to setup');
            if (role == 'student') return studentProfileSetupPath;
            if (role == 'startup') return startupProfileSetupPath;
            return roleSelectionPath; // Force re-selection if role is lost/empty
          }
        }

        return null;
      },
    );
  }
}
