import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundSosService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('kawach/background_sos');

  bool _isRunning = false;
  String? _activeEmergencyId;

  bool get isRunning => _isRunning;
  String? get activeEmergencyId => _activeEmergencyId;

  Future<void> start({
    required String emergencyId,
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod<void>('start', {
        'emergencyId': emergencyId,
        'title': title,
        'body': body,
      });
      _isRunning = true;
      _activeEmergencyId = emergencyId;
      notifyListeners();
    } catch (error) {
      debugPrint('BackgroundSosService.start failed: $error');
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (error) {
      debugPrint('BackgroundSosService.stop failed: $error');
    } finally {
      _isRunning = false;
      _activeEmergencyId = null;
      notifyListeners();
    }
  }

  Future<void> refreshNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod<void>('updateNotification', {
        'title': title,
        'body': body,
      });
    } catch (error) {
      debugPrint('BackgroundSosService.refreshNotification failed: $error');
    }
  }
}
