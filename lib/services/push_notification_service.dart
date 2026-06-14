import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/client.dart';
import '../api/notifications_api.dart';
import '../providers/notifications_provider.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static NotificationsProvider? _provider;
  static String? _cachedFcmToken;

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static void bindProvider(NotificationsProvider provider) {
    _provider = provider;
  }

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase.initializeApp skipped: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayload(payload);
        }
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'optic_alerts',
            'Optic Alerts',
            description: 'Order, transfer, and account alerts',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ));
    }

    await _requestPlatformPermissions();

    final messaging = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    messaging.onTokenRefresh.listen((token) => _registerToken(token));

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleRemoteMessage(initial);
    }

    await syncTokenWithBackend();

    _initialized = true;
  }

  static Future<void> _requestPlatformPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('Android notification permission not granted');
      }
      return;
    }

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('iOS notification permission not granted');
      }
    }
  }

  static Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  static Future<bool> notificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return true;
  }

  static Future<void> syncTokenWithBackend() async {
    final authToken = await getStoredToken();
    if (authToken == null) return;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      _cachedFcmToken = fcmToken;
      await registerDeviceToken(
        fcmToken,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  static Future<void> unregisterFromBackend() async {
    try {
      await unregisterDeviceToken(token: _cachedFcmToken);
    } catch (_) {}
    _cachedFcmToken = null;
  }

  static Future<void> _registerToken(String token) async {
    _cachedFcmToken = token;
    final authToken = await getStoredToken();
    if (authToken == null) return;
    try {
      await registerDeviceToken(token, platform: Platform.isIOS ? 'ios' : 'android');
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    _provider?.refreshSilently();
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Optic';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    _showLocalNotification(title, body, message.data);
  }

  static void _onMessageOpened(RemoteMessage message) {
    _handleRemoteMessage(message);
  }

  static void _handleRemoteMessage(RemoteMessage message) {
    _provider?.refreshSilently();
    final route = message.data['route']?.toString();
    if (route == null || route.isEmpty) return;
    _navigateToRoute(route, entityId: int.tryParse('${message.data['entity_id']}'));
  }

  static void _handlePayload(String payload) {
    try {
      final map = Map<String, dynamic>.from(
        payload.startsWith('{')
            ? (jsonDecode(payload) as Map<String, dynamic>)
            : {'route': payload},
      );
      final route = map['route']?.toString();
      if (route == null || route.isEmpty) return;
      _navigateToRoute(route, entityId: int.tryParse('${map['entity_id']}'));
    } catch (_) {}
  }

  static void _navigateToRoute(String route, {int? entityId}) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    final args = entityId != null ? {'id': entityId} : null;
    nav.pushNamed(route, arguments: args);
  }

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final payload = jsonEncode({
      'route': data['route'],
      'entity_id': data['entity_id'],
    });

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'optic_alerts',
          'Optic Alerts',
          channelDescription: 'Order, transfer, and account alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}
