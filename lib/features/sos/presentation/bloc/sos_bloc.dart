import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/sos_alert.dart';
import '../../domain/usecases/trigger_sos.dart';
import '../../domain/usecases/cancel_sos.dart';
import 'sos_event.dart';
import 'sos_state.dart';

// ============================================================
// SosBloc – Presentation-layer state machine for SOS
// ============================================================

/// Manages SOS lifecycle: countdown → trigger → active → cancel/resolve.
///
/// Implements a simple BLoC pattern using [ChangeNotifier] to stay
/// compatible with the existing Provider-based architecture while
/// following the event/state separation of BLoC.
class SosBloc extends ChangeNotifier {
  final TriggerSos _triggerSos;
  final CancelSos _cancelSos;

  SosState _state = const SosInitial();
  SosState get state => _state;

  Timer? _countdownTimer;
  StreamSubscription<SosAlert?>? _alertSubscription;

  SosBloc({
    required TriggerSos triggerSos,
    required CancelSos cancelSos,
  })  : _triggerSos = triggerSos,
        _cancelSos = cancelSos;

  void add(SosEvent event) {
    if (event is SosTriggerRequested) {
      _onTriggerRequested(event);
    } else if (event is SosCancelRequested) {
      _onCancelRequested(event);
    } else if (event is SosCountdownTick) {
      _onCountdownTick(event);
    } else if (event is SosAlertUpdated) {
      _onAlertUpdated(event);
    }
  }

  void _emit(SosState newState) {
    _state = newState;
    notifyListeners();
  }

  // ── Trigger with countdown ────────────────────────────────────
  void _onTriggerRequested(SosTriggerRequested event) {
    var remaining = AppConstants.sosCountdownSeconds;
    _emit(SosCountdown(remaining));

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        _executeTrigger(event);
      } else {
        _emit(SosCountdown(remaining));
      }
    });
  }

  Future<void> _executeTrigger(SosTriggerRequested event) async {
    _emit(const SosTriggering());

    final userId = SupabaseClientProvider.currentUserId;
    if (userId == null) {
      _emit(const SosError('Not authenticated'));
      return;
    }

    try {
      final alert = await _triggerSos(
        userId: userId,
        trigger: event.trigger,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      _emit(SosActive(alert));
    } catch (e) {
      _emit(SosError(e.toString()));
    }
  }

  // ── Cancel ────────────────────────────────────────────────────
  void _onCancelRequested(SosCancelRequested event) {
    _countdownTimer?.cancel();

    if (state is SosCountdown) {
      _emit(const SosCancelled());
      return;
    }

    _cancelSos(event.alertId).then((_) {
      _emit(const SosCancelled());
    }).catchError((e) {
      _emit(SosError(e.toString()));
    });
  }

  void _onCountdownTick(SosCountdownTick event) {
    _emit(SosCountdown(event.remainingSeconds));
  }

  void _onAlertUpdated(SosAlertUpdated event) {
    _emit(SosActive(event.alert));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }
}
