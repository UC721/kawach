import 'dart:async';
import 'dart:isolate';

// ============================================================
// MonitoringIsolate – Dedicated isolate for safety monitoring
// ============================================================

/// Runs sensor processing and anomaly detection on a separate
/// isolate to avoid blocking the UI thread.
///
/// Communicates with the main isolate via [SendPort] / [ReceivePort].
class MonitoringIsolate {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Spawn the monitoring isolate.
  Future<void> start({
    required Function(MonitoringEvent) onEvent,
  }) async {
    if (_isRunning) return;

    _receivePort = ReceivePort();
    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is MonitoringEvent) {
        onEvent(message);
      }
    });

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort!.sendPort,
    );
    _isRunning = true;
  }

  /// Send a command to the monitoring isolate.
  void sendCommand(MonitoringCommand command) {
    _sendPort?.send(command);
  }

  /// Terminate the monitoring isolate.
  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _receivePort = null;
    _sendPort = null;
    _isRunning = false;
  }

  static void _isolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is MonitoringCommand) {
        // Process commands from main isolate
        switch (message.type) {
          case CommandType.startSensors:
            mainSendPort.send(MonitoringEvent(
              type: EventType.sensorStarted,
              data: {},
            ));
            break;
          case CommandType.stopSensors:
            mainSendPort.send(MonitoringEvent(
              type: EventType.sensorStopped,
              data: {},
            ));
            break;
          case CommandType.checkStatus:
            mainSendPort.send(MonitoringEvent(
              type: EventType.statusUpdate,
              data: {'running': true},
            ));
            break;
        }
      }
    });
  }
}

class MonitoringEvent {
  final EventType type;
  final Map<String, dynamic> data;
  const MonitoringEvent({required this.type, required this.data});
}

enum EventType { sensorStarted, sensorStopped, anomalyDetected, statusUpdate }

class MonitoringCommand {
  final CommandType type;
  final Map<String, dynamic>? params;
  const MonitoringCommand({required this.type, this.params});
}

enum CommandType { startSensors, stopSensors, checkStatus }
