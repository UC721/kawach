import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

enum JourneyState { safe, delayed, sos }

/// Streams a user's live journey metrics to the backend.
/// Throttles location updates to every 10 meters or 15 seconds to save battery,
/// but instantly forces an update if JourneyState switches to sos.
class SafetyStreamerService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Battery _battery = Battery();

  StreamSubscription<Position>? _positionStreamSub;
  Timer? _periodicTimer;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  JourneyState _currentState = JourneyState.safe;
  JourneyState get currentState => _currentState;

  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  void startStreaming(AuthService auth) {
    if (_isStreaming) return;
    if (auth.currentUserId == null) return;

    _isStreaming = true;
    _currentState = JourneyState.safe;

    // Stream position with 10 meters distance filter
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 meters throttle
      ),
    ).listen((Position position) {
      _lastPosition = position;
      _pushUpdate(auth.currentUserId!);
    });

    // Also force an update every 15 seconds as a heartbeat
    _periodicTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_lastPosition != null) {
        _pushUpdate(auth.currentUserId!);
      }
    });

    notifyListeners();
  }

  void updateJourneyState(JourneyState newState, AuthService auth) {
    if (_currentState == newState) return;
    _currentState = newState;

    // Instantly force an update on state change, especially SOS
    if (_lastPosition != null && auth.currentUserId != null) {
      _pushUpdate(auth.currentUserId!, force: true);
    }
    notifyListeners();
  }

  Future<void> _pushUpdate(String userId, {bool force = false}) async {
    if (!_isStreaming || _lastPosition == null) return;

    final now = DateTime.now();

    // Throttle checks (already handled by distanceFilter, but ensure time throttle too unless forced)
    if (!force && _lastUpdateTime != null) {
      if (now.difference(_lastUpdateTime!).inSeconds < 10) {
        return; // Don't spam if multiple events hit
      }
    }

    _lastUpdateTime = now;

    try {
      final batteryLevel = await _battery.batteryLevel;

      await _supabase.from('live_journeys').upsert({
        'user_id': userId,
        'latitude': _lastPosition!.latitude,
        'longitude': _lastPosition!.longitude,
        'accuracy': _lastPosition!.accuracy,
        'battery_level': batteryLevel,
        'state': _currentState.name,
        'updated_at': now.toIso8601String(),
      });
      debugPrint(
          '--- KAWACH: SafetyStreamer pushed update: ${_currentState.name} ---');
    } catch (e) {
      debugPrint('Error pushing live journey update: $e');
    }
  }

  void stopStreaming(AuthService auth) {
    _positionStreamSub?.cancel();
    _periodicTimer?.cancel();

    if (_isStreaming && auth.currentUserId != null) {
      // Optional: Clean up or mark journey as ended in DB
      _supabase
          .from('live_journeys')
          .delete()
          .eq('user_id', auth.currentUserId!);
    }

    _isStreaming = false;
    _lastPosition = null;
    _lastUpdateTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
