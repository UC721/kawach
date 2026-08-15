import '../../domain/entities/sos_alert.dart';

// ============================================================
// SosEvent – BLoC events for SOS feature
// ============================================================

abstract class SosEvent {
  const SosEvent();
}

class SosTriggerRequested extends SosEvent {
  final SosTriggerType trigger;
  final double? latitude;
  final double? longitude;

  const SosTriggerRequested({
    required this.trigger,
    this.latitude,
    this.longitude,
  });
}

class SosCancelRequested extends SosEvent {
  final String alertId;
  const SosCancelRequested(this.alertId);
}

class SosResolveRequested extends SosEvent {
  final String alertId;
  const SosResolveRequested(this.alertId);
}

class SosAlertUpdated extends SosEvent {
  final SosAlert alert;
  const SosAlertUpdated(this.alert);
}

class SosCountdownTick extends SosEvent {
  final int remainingSeconds;
  const SosCountdownTick(this.remainingSeconds);
}
