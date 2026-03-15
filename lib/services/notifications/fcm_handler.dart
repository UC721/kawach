import 'dart:async';

// ============================================================
// FcmHandler – Firebase Cloud Messaging handler
// ============================================================

/// Manages FCM token registration, foreground/background message
/// handling, and notification display.
///
/// Requires `firebase_messaging` to be initialised in `main.dart`.
class FcmHandler {
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<NotificationPayload> _notificationStream =
      StreamController<NotificationPayload>.broadcast();
  Stream<NotificationPayload> get notifications => _notificationStream.stream;

  /// Initialise FCM and request notification permissions.
  Future<void> initialize() async {
    // In production:
    // 1. Request notification permissions
    // 2. Get FCM token
    // 3. Register foreground message handler
    // 4. Register background message handler
    // 5. Handle notification tap (app opened from notification)
  }

  /// Register the FCM token with the backend.
  Future<void> registerToken(String userId) async {
    if (_fcmToken == null) return;
    // In production: upsert token in Supabase users table
  }

  /// Handle an incoming FCM message.
  void handleMessage(Map<String, dynamic> data) {
    final payload = NotificationPayload(
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      data: data,
      receivedAt: DateTime.now(),
    );
    _notificationStream.add(payload);
  }

  NotificationType _parseType(String? type) {
    switch (type) {
      case 'sos_alert':
        return NotificationType.sosAlert;
      case 'guardian_update':
        return NotificationType.guardianUpdate;
      case 'safety_warning':
        return NotificationType.safetyWarning;
      default:
        return NotificationType.general;
    }
  }

  void dispose() => _notificationStream.close();
}

class NotificationPayload {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const NotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.receivedAt,
  });
}

enum NotificationType { sosAlert, guardianUpdate, safetyWarning, general }
