import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/guardian_model.dart';

class NotificationService extends ChangeNotifier {
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance; // REMOVED
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request notification permission
    // FCM setup removed
    // In the future, request permissions via another provider (like OneSignal)
    await Future.delayed(const Duration(milliseconds: 500));
    _fcmToken = 'mock-token-for-supabase-migration';
    notifyListeners();

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

    // Removed FirebaseMessaging listeners
  }

  // ───────────────── Notify Guardians ─────────────────

  Future<void> notifyGuardians({
    required List<GuardianModel> guardians,
    required String emergencyId,
    required String userId,
    double? lat,
    double? lng,
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
          'lat': lat?.toString() ?? '',
          'lng': lng?.toString() ?? '',
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
    // FCM Http call removed. 
    // Usually this is done server-side anyway.
    debugPrint('Mock push notification sent to $token: $title / $body');
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

  // _showLocalNotification(RemoteMessage message) removed
}