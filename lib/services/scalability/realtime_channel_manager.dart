import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/scalability_config_model.dart';

/// Metadata for a tracked Realtime channel.
class _ChannelEntry {
  final String channelName;
  DateTime lastActivity;
  bool isConnected;

  _ChannelEntry({
    required this.channelName,
    DateTime? lastActivity,
    this.isConnected = true,
  }) : lastActivity = lastActivity ?? DateTime.now();
}

/// Manages Supabase Realtime channel subscriptions at scale.
///
/// With millions of concurrent users each subscribing to their own
/// emergency, guardian, and location channels, unbounded channel
/// creation would exhaust server resources. This manager:
///
/// * Enforces a maximum number of concurrent channels.
/// * Auto-closes idle channels.
/// * Provides automatic reconnection on drop.
class RealtimeChannelManager extends ChangeNotifier {
  final ScalabilityConfig _config;

  final Map<String, _ChannelEntry> _channels = {};
  Timer? _idleCheckTimer;

  int get activeChannels => _channels.length;
  int get connectedChannels =>
      _channels.values.where((c) => c.isConnected).length;
  bool get isAtCapacity =>
      _channels.length >= _config.maxRealtimeChannels;

  RealtimeChannelManager({ScalabilityConfig? config})
      : _config = config ?? const ScalabilityConfig();

  /// Start the idle-channel reaper.
  void startIdleMonitor() {
    _idleCheckTimer?.cancel();
    _idleCheckTimer = Timer.periodic(
      _config.channelIdleTimeout,
      (_) => _closeIdleChannels(),
    );
  }

  /// Register a new channel.
  ///
  /// Returns `false` if the maximum number of channels has been
  /// reached and [channelName] is not already tracked.
  bool subscribe(String channelName) {
    if (_channels.containsKey(channelName)) {
      _channels[channelName]!.lastActivity = DateTime.now();
      _channels[channelName]!.isConnected = true;
      return true;
    }

    if (isAtCapacity) return false;

    _channels[channelName] = _ChannelEntry(channelName: channelName);
    notifyListeners();
    return true;
  }

  /// Unsubscribe from a channel.
  void unsubscribe(String channelName) {
    _channels.remove(channelName);
    notifyListeners();
  }

  /// Record activity on a channel (keeps it alive).
  void touch(String channelName) {
    _channels[channelName]?.lastActivity = DateTime.now();
  }

  /// Mark a channel as disconnected (e.g. after a network drop).
  void markDisconnected(String channelName) {
    final entry = _channels[channelName];
    if (entry != null) {
      entry.isConnected = false;
      notifyListeners();
    }
  }

  /// Attempt reconnection for all disconnected channels.
  ///
  /// Returns the names of channels that were marked for reconnection.
  List<String> reconnectDisconnected() {
    final reconnected = <String>[];
    for (final entry in _channels.values) {
      if (!entry.isConnected) {
        entry.isConnected = true;
        entry.lastActivity = DateTime.now();
        reconnected.add(entry.channelName);
      }
    }
    if (reconnected.isNotEmpty) notifyListeners();
    return reconnected;
  }

  /// Close channels that have been idle longer than the configured
  /// timeout.
  void _closeIdleChannels() {
    final cutoff =
        DateTime.now().subtract(_config.channelIdleTimeout);
    final idle = _channels.entries
        .where((e) => e.value.lastActivity.isBefore(cutoff))
        .map((e) => e.key)
        .toList();
    for (final name in idle) {
      _channels.remove(name);
    }
    if (idle.isNotEmpty) notifyListeners();
  }

  /// Return a snapshot of all tracked channels.
  List<String> get channelNames => List.unmodifiable(_channels.keys);

  /// Whether a specific channel is currently tracked.
  bool isSubscribed(String channelName) =>
      _channels.containsKey(channelName);

  @override
  void dispose() {
    _idleCheckTimer?.cancel();
    super.dispose();
  }
}
