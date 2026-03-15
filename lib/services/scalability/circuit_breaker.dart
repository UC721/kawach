import 'package:flutter/foundation.dart';

import '../../models/scalability_config_model.dart';

/// Possible states of a circuit breaker.
enum CircuitState { closed, open, halfOpen }

/// Circuit-breaker for external service calls.
///
/// Prevents cascading failures by short-circuiting calls to a
/// backend that is known to be unhealthy.  The lifecycle is:
///
/// ```
///   CLOSED  ──(failures ≥ threshold)──▶  OPEN
///      ▲                                   │
///      │                            (reset timeout)
///      │                                   ▼
///      └──(successes ≥ threshold)──  HALF-OPEN
/// ```
class CircuitBreaker extends ChangeNotifier {
  final ScalabilityConfig _config;
  final String name;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _openedAt;

  CircuitState get state => _state;
  int get failureCount => _failureCount;

  CircuitBreaker({
    required this.name,
    ScalabilityConfig? config,
  }) : _config = config ?? const ScalabilityConfig();

  /// Execute [action] through the circuit breaker.
  ///
  /// If the circuit is open, returns the result of [fallback]
  /// instead of calling [action].
  Future<T> execute<T>(
    Future<T> Function() action, {
    required Future<T> Function() fallback,
  }) async {
    if (!allowRequest) {
      return fallback();
    }

    try {
      final result = await action();
      _recordSuccess();
      return result;
    } catch (e) {
      _recordFailure();
      return fallback();
    }
  }

  /// Whether the breaker currently allows requests through.
  bool get allowRequest {
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        if (_openedAt != null &&
            DateTime.now().difference(_openedAt!) >=
                _config.circuitBreakerResetTimeout) {
          _transitionTo(CircuitState.halfOpen);
          return true;
        }
        return false;
      case CircuitState.halfOpen:
        return true;
    }
  }

  void _recordSuccess() {
    _failureCount = 0;
    switch (_state) {
      case CircuitState.halfOpen:
        _successCount++;
        if (_successCount >= _config.circuitBreakerSuccessThreshold) {
          _transitionTo(CircuitState.closed);
        }
        break;
      case CircuitState.closed:
      case CircuitState.open:
        break;
    }
  }

  void _recordFailure() {
    _failureCount++;
    switch (_state) {
      case CircuitState.closed:
        if (_failureCount >= _config.circuitBreakerFailureThreshold) {
          _transitionTo(CircuitState.open);
        }
        break;
      case CircuitState.halfOpen:
        _transitionTo(CircuitState.open);
        break;
      case CircuitState.open:
        break;
    }
  }

  void _transitionTo(CircuitState newState) {
    _state = newState;
    if (newState == CircuitState.open) {
      _openedAt = DateTime.now();
      _successCount = 0;
    } else if (newState == CircuitState.closed) {
      _failureCount = 0;
      _successCount = 0;
      _openedAt = null;
    } else {
      _successCount = 0;
    }
    notifyListeners();
  }

  /// Manually reset the breaker.
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _openedAt = null;
    notifyListeners();
  }
}
