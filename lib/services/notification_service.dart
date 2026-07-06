import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  void Function(String?)? onNotificationTap;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    // On Web, we need to skip some of the mobile-specific logic that would crash.
    try {
      // 1. Request Permission (iOS & Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // 2. Setup Local Notifications for Foreground
      if (!kIsWeb) {
        const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
        const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
        const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse details) {
            debugPrint('Notification tapped: ${details.payload}');
            if (onNotificationTap != null) {
              onNotificationTap!(details.payload);
            }
          },
        );

        // 3. Create High Importance Channel for Android (Skip on Web as Platform.isAndroid crashes)
        if (defaultTargetPlatform == TargetPlatform.android) {
          await _localNotifications
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(_channel);
        }

      // 5. Setup Background Handler (Mobile only)
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 6. Handle notification taps when app is in background but still running
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Notification tapped while app in background: ${message.data}');
          _handleMessageTap(message);
        });

        // 7. Check if app was opened from a terminated state via a notification
        RemoteMessage? initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('App opened from terminated state via notification: ${initialMessage.data}');
          // Delaying slightly to ensure onNotificationTap listener is set up in main.dart
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleMessageTap(initialMessage);
          });
        }
      }

      // 4. Handle Foreground Messages (Works on Web)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        
        if (notification != null && !kIsWeb) {
          showLocalNotification(
            notification.hashCode,
            notification.title ?? '',
            notification.body ?? '',
            payload: jsonEncode({
              'type': message.data['type'] ?? 'generic',
              'relatedId': message.data['relatedId'] ?? '',
              'subId': message.data['subId'] ?? '',
            }),
          );
        }
      });

      // 8. Get FCM Token
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
    } catch (e) {
      debugPrint("NotificationService Initialization Error (Handled): $e");
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (onNotificationTap != null) {
      onNotificationTap!(jsonEncode({
        'type': message.data['type'] ?? 'generic',
        'relatedId': message.data['relatedId'] ?? '',
        'subId': message.data['subId'] ?? '',
      }));
    }
  }

  Future<void> showLocalNotification(int id, String title, String body, {String? payload}) async {
    if (kIsWeb) return; // Browsers show native notifications directly
    
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: _channel.importance,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
