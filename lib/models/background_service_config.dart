/// Configuration for KAWACH background services.
///
/// Controls which safety monitors stay active in the background,
/// notification appearance, and timing intervals.
class BackgroundServiceConfig {
  /// Human-readable title shown in the foreground-service notification.
  final String notificationTitle;

  /// Body text for the foreground-service notification.
  final String notificationBody;

  /// How often (in seconds) the location is uploaded while backgrounded.
  final int locationUpdateIntervalSec;

  /// Whether location tracking should continue in the background.
  final bool enableLocationTracking;

  /// Whether accelerometer-based shake detection stays active.
  final bool enableShakeDetection;

  /// Whether accelerometer-based snatch/motion detection stays active.
  final bool enableMotionDetection;

  /// Whether speech-to-text panic-phrase monitoring stays active.
  final bool enableVoiceDetection;

  /// Minimum number of seconds the service must run before auto-stop is
  /// allowed (guards against accidental immediate teardown).
  final int autoStopThresholdSec;

  const BackgroundServiceConfig({
    this.notificationTitle = 'KAWACH Active',
    this.notificationBody = 'Your safety shield is running',
    this.locationUpdateIntervalSec = 15,
    this.enableLocationTracking = true,
    this.enableShakeDetection = true,
    this.enableMotionDetection = true,
    this.enableVoiceDetection = false,
    this.autoStopThresholdSec = 30,
  });

  /// Preset used during an active emergency – all monitors on, fast updates.
  factory BackgroundServiceConfig.emergency() {
    return const BackgroundServiceConfig(
      notificationTitle: '🚨 KAWACH Emergency Active',
      notificationBody: 'Tracking & evidence capture running',
      locationUpdateIntervalSec: 5,
      enableLocationTracking: true,
      enableShakeDetection: true,
      enableMotionDetection: true,
      enableVoiceDetection: true,
      autoStopThresholdSec: 0,
    );
  }

  /// Lightweight monitoring preset – location only, longer interval.
  factory BackgroundServiceConfig.passive() {
    return const BackgroundServiceConfig(
      notificationTitle: 'KAWACH Monitoring',
      notificationBody: 'Passive safety monitoring active',
      locationUpdateIntervalSec: 60,
      enableLocationTracking: true,
      enableShakeDetection: false,
      enableMotionDetection: false,
      enableVoiceDetection: false,
      autoStopThresholdSec: 60,
    );
  }

  BackgroundServiceConfig copyWith({
    String? notificationTitle,
    String? notificationBody,
    int? locationUpdateIntervalSec,
    bool? enableLocationTracking,
    bool? enableShakeDetection,
    bool? enableMotionDetection,
    bool? enableVoiceDetection,
    int? autoStopThresholdSec,
  }) {
    return BackgroundServiceConfig(
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
      locationUpdateIntervalSec:
          locationUpdateIntervalSec ?? this.locationUpdateIntervalSec,
      enableLocationTracking:
          enableLocationTracking ?? this.enableLocationTracking,
      enableShakeDetection: enableShakeDetection ?? this.enableShakeDetection,
      enableMotionDetection:
          enableMotionDetection ?? this.enableMotionDetection,
      enableVoiceDetection: enableVoiceDetection ?? this.enableVoiceDetection,
      autoStopThresholdSec: autoStopThresholdSec ?? this.autoStopThresholdSec,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'locationUpdateIntervalSec': locationUpdateIntervalSec,
      'enableLocationTracking': enableLocationTracking,
      'enableShakeDetection': enableShakeDetection,
      'enableMotionDetection': enableMotionDetection,
      'enableVoiceDetection': enableVoiceDetection,
      'autoStopThresholdSec': autoStopThresholdSec,
    };
  }

  factory BackgroundServiceConfig.fromMap(Map<String, dynamic> map) {
    return BackgroundServiceConfig(
      notificationTitle:
          map['notificationTitle'] as String? ?? 'KAWACH Active',
      notificationBody:
          map['notificationBody'] as String? ?? 'Your safety shield is running',
      locationUpdateIntervalSec:
          map['locationUpdateIntervalSec'] as int? ?? 15,
      enableLocationTracking:
          map['enableLocationTracking'] as bool? ?? true,
      enableShakeDetection:
          map['enableShakeDetection'] as bool? ?? true,
      enableMotionDetection:
          map['enableMotionDetection'] as bool? ?? true,
      enableVoiceDetection:
          map['enableVoiceDetection'] as bool? ?? false,
      autoStopThresholdSec:
          map['autoStopThresholdSec'] as int? ?? 30,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackgroundServiceConfig &&
        other.notificationTitle == notificationTitle &&
        other.notificationBody == notificationBody &&
        other.locationUpdateIntervalSec == locationUpdateIntervalSec &&
        other.enableLocationTracking == enableLocationTracking &&
        other.enableShakeDetection == enableShakeDetection &&
        other.enableMotionDetection == enableMotionDetection &&
        other.enableVoiceDetection == enableVoiceDetection &&
        other.autoStopThresholdSec == autoStopThresholdSec;
  }

  @override
  int get hashCode {
    return Object.hash(
      notificationTitle,
      notificationBody,
      locationUpdateIntervalSec,
      enableLocationTracking,
      enableShakeDetection,
      enableMotionDetection,
      enableVoiceDetection,
      autoStopThresholdSec,
    );
  }
}
