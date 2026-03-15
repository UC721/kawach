/// The three concentric rings of the KAWACH architecture.
///
/// ```
/// ┌──────────────────────────────────────────────────────┐
/// │                 CLOUD (outermost)                    │
/// │   Supabase backend, push notifications, streaming   │
/// │  ┌──────────────────────────────────────────────┐   │
/// │  │              MESH (middle)                    │   │
/// │  │   SMS relay, guardian network, offline queue  │   │
/// │  │  ┌──────────────────────────────────────┐    │   │
/// │  │  │          EDGE (innermost)             │    │   │
/// │  │  │   Sensors, local storage, siren,     │    │   │
/// │  │  │   GPS, recording, fake call          │    │   │
/// │  │  └──────────────────────────────────────┘    │   │
/// │  └──────────────────────────────────────────────┘   │
/// └──────────────────────────────────────────────────────┘
/// ```
///
/// All rings operate independently when others fail.
enum Ring {
  /// Innermost ring – always available on-device.
  /// Handles: GPS, sensors, local storage, siren, fake call, recording.
  edge,

  /// Middle ring – offline relay capabilities.
  /// Handles: SMS gateway, guardian network alerts, offline emergency queue.
  mesh,

  /// Outermost ring – scalable cloud backend.
  /// Handles: Supabase DB, push notifications, live streaming, analytics.
  cloud,
}

/// Snapshot of which rings are currently operational.
class RingState {
  /// Edge ring is always available (device-local).
  final bool edgeAvailable;

  /// Mesh ring requires SMS gateway or local network for peer relay.
  final bool meshAvailable;

  /// Cloud ring requires internet connectivity to Supabase backend.
  final bool cloudAvailable;

  /// Timestamp of last state update.
  final DateTime updatedAt;

  const RingState({
    this.edgeAvailable = true,
    this.meshAvailable = false,
    this.cloudAvailable = false,
    required this.updatedAt,
  });

  RingState copyWith({
    bool? edgeAvailable,
    bool? meshAvailable,
    bool? cloudAvailable,
  }) {
    return RingState(
      edgeAvailable: edgeAvailable ?? this.edgeAvailable,
      meshAvailable: meshAvailable ?? this.meshAvailable,
      cloudAvailable: cloudAvailable ?? this.cloudAvailable,
      updatedAt: DateTime.now(),
    );
  }

  /// The outermost ring that is currently operational.
  Ring get activeRing {
    if (cloudAvailable) return Ring.cloud;
    if (meshAvailable) return Ring.mesh;
    return Ring.edge;
  }

  /// All currently available rings (always includes [Ring.edge]).
  Set<Ring> get availableRings => {
        if (edgeAvailable) Ring.edge,
        if (meshAvailable) Ring.mesh,
        if (cloudAvailable) Ring.cloud,
      };

  /// True when at least one ring beyond Edge is reachable.
  bool get hasMeshOrCloud => meshAvailable || cloudAvailable;

  @override
  String toString() =>
      'RingState(edge: $edgeAvailable, mesh: $meshAvailable, '
      'cloud: $cloudAvailable, active: ${activeRing.name})';
}
