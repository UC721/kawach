import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../models/guardian_model.dart';
import '../utils/constants.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request notification permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM Token
    try {
      _fcmToken = await _fcm.getToken();
      notifyListeners();
    } catch (e) {
      debugPrint('FCM Token skipped: Real google-services.json missing ($e)');
    }

    // Initialize local notifications (skip for Web)
    if (!kIsWeb) {
      const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosInit = DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(settings: initSettings);
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });
  }

  // ───────────────── Notify Guardians ─────────────────

  Future<void> notifyGuardians({
    required List<GuardianModel> guardians,
    required String emergencyId,
    required String userId,
    GeoPoint? location,
  }) async {
    for (final guardian in guardians) {
      if (guardian.fcmToken == null) continue;

      await _sendFcmMessage(
        token: guardian.fcmToken!,
        title: '🚨 KAWACH EMERGENCY ALERT',
        body:
        '${guardian.name.isNotEmpty ? "Your contact" : "User"} has triggered SOS! Tap to view location.',
        data: {
          'emergencyId': emergencyId,
          'userId': userId,
          'type': 'emergency',
          'lat': location?.latitude.toString() ?? '',
          'lng': location?.longitude.toString() ?? '',
        },
      );
    }
  }

  Future<void> _sendFcmMessage({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_SERVER_KEY',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );
    } catch (_) {}
  }

  // ───────────────── Local Notification ─────────────────

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'kawach_emergency',
      'KAWACH Emergency',
      channelDescription: 'Emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'KAWACH',
        body: notification.body ?? '',
      );
    }
  }

  // ───────────────── Save Token ─────────────────

  Future<void> saveFcmToken(String userId) async {
    if (_fcmToken == null) return;
    
    // Simulate saving FCM token successfully
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mocked saving FCM Token: $_fcmToken for User: $userId');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  // Handle background notifications here
}