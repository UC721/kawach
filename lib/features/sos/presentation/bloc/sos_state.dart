import '../../domain/entities/sos_alert.dart';

// ============================================================
// SosState – BLoC states for SOS feature
// ============================================================

abstract class SosState {
  const SosState();
}

class SosInitial extends SosState {
  const SosInitial();
}

class SosCountdown extends SosState {
  final int remainingSeconds;
  const SosCountdown(this.remainingSeconds);
}

class SosTriggering extends SosState {
  const SosTriggering();
}

class SosActive extends SosState {
  final SosAlert alert;
  const SosActive(this.alert);
}

class SosCancelled extends SosState {
  const SosCancelled();
}

class SosResolved extends SosState {
  const SosResolved();
}

class SosError extends SosState {
  final String message;
  const SosError(this.message);
}
