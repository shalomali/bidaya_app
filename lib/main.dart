import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'services/auth_service.dart';
import 'core/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'core/utils/notification_router.dart';
import 'core/connectivity_wrapper.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

void main() async {
  debugPrint('--- APP STARTING ---');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('WidgetsFlutterBinding initialized');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase initialized');
  
  // Initialze Crashlytics
  FlutterError.onError = (errorDetails) {
    debugPrint('Flutter Error: ${errorDetails.exception}');
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Notifications
  final notificationService = NotificationService();
  debugPrint('Initializing NotificationService...');
  await notificationService.initialize();
  debugPrint('NotificationService initialized');

  // Enable Edge-to-Edge Immersion
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) {
          debugPrint('Creating AuthService...');
          return AuthService();
        }),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: const BidayaApp(),
    ),
  );
  debugPrint('runApp called');
}

class BidayaApp extends StatefulWidget {
  const BidayaApp({super.key});

  @override
  State<BidayaApp> createState() => _BidayaAppState();
}

class _BidayaAppState extends State<BidayaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(context.read<AuthService>());
    _setupNotificationBridge();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    NotificationService().onNotificationTap = (payload) {
      if (payload != null && payload.isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(payload);
          NotificationRouter.navigateWithRouter(_router, data);
        } catch (e) {
          debugPrint('Error navigating from notification: $e');
        }
      }
    };
  }

  void _setupNotificationBridge() {
    // Listen for new Firestore notifications and show local alerts if app is foreground
    final authService = context.read<AuthService>();
    final dbService = DatabaseService();

    authService.user.listen((user) {
      if (user != null) {
        dbService.getNotifications(user.uid).listen((notifications) {
          if (notifications.isNotEmpty) {
            final latest = notifications.first;
            // Only show if it matches current time (within 10s) to avoid spamming old ones on login
            final now = DateTime.now();
            if (now.difference(latest.createdAt).inSeconds.abs() < 10 && !latest.isRead) {
              NotificationService().showLocalNotification(
                latest.hashCode,
                latest.title,
                latest.message,
                payload: jsonEncode({
                  'type': latest.type ?? 'generic',
                  'relatedId': latest.relatedId ?? '',
                  'subId': latest.subId ?? '',
                  'role': latest.role ?? '',
                }),
              );
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // While the app is determining the initial login state, we keep it stable.
    // The GoRouter itself handles the splashPath as the initial location.
    
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Bidaya Platform MVP v1.4',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ConnectivityWrapper(child: child!),
    );
  }
}
