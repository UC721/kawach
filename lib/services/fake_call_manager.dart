import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

import 'notification_service.dart';

class CallerIdentity {
  final String name;
  final String number;
  final String? imageAsset;

  const CallerIdentity({
    required this.name,
    required this.number,
    this.imageAsset,
  });
}

class FakeCallManager {
  static final FakeCallManager _instance = FakeCallManager._internal();
  static FakeCallManager get instance => _instance;

  FakeCallManager._internal();

  final AudioPlayer _ringtonePlayer = AudioPlayer();
  Timer? _callTimer;
  bool _isRinging = false;

  /// Schedules a fake call after a specific delay.
  void scheduleFakeCall(Duration delay, CallerIdentity caller) {
    debugPrint('--- KAWACH: Scheduling Fake Call from ${caller.name} in ${delay.inSeconds} seconds ---');
    
    _callTimer?.cancel();
    _callTimer = Timer(delay, () => _triggerCall(caller));
  }

  /// Cancels any scheduled fake calls.
  void cancelScheduledCall() {
    _callTimer?.cancel();
    _callTimer = null;
    debugPrint('--- KAWACH: Fake Call Cancelled ---');
  }

  Future<void> _triggerCall(CallerIdentity caller) async {
    _isRinging = true;

    // Start playing looping ringtone
    try {
      _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      // Assuming a generic ringtone asset exists or use system default
      await _ringtonePlayer.play(AssetSource('audio/ringtone.mp3'));
    } catch (e) {
      debugPrint('Could not play ringtone: $e');
    }

    // Trigger high-priority, full-screen intent notification
    await _showIncomingCallNotification(caller);

    // Auto-timeout after 30 seconds if not answered/declined
    Timer(const Duration(seconds: 30), () {
      if (_isRinging) {
        endCall();
      }
    });
  }

  Future<void> _showIncomingCallNotification(CallerIdentity caller) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'incoming_call',
      'Incoming Calls',
      channelDescription: 'Used for Fake Call feature',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'decline',
          'Decline',
          titleColor: Color.fromARGB(255, 255, 0, 0),
        ),
        AndroidNotificationAction(
          'answer',
          'Answer',
          titleColor: Color.fromARGB(255, 0, 255, 0),
        ),
      ],
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.show(
      888, // Unique ID for fake calls
      'Incoming Call',
      caller.name,
      platformChannelSpecifics,
    );
  }

  /// Called when the user answers or declines the call, or after timeout.
  void endCall() {
    if (!_isRinging) return;
    _isRinging = false;
    _ringtonePlayer.stop();
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.cancel(888);
    
    debugPrint('--- KAWACH: Fake Call Ended ---');
  }
}
