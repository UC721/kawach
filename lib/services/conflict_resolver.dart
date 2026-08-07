import '../models/emergency_model.dart';

/// Pure, unit-testable conflict-resolution rules for offline-first sync.
///
/// Rule set:
/// - Emergencies are keyed by `emergency_id`; syncing is idempotent (an
///   already-synced row is not duplicated).
/// - For status changes the server is authoritative (a resolve/cancel coming
///   from another device wins over a local "still active" copy).
/// - For payload fields (lat/lng/media URLs) the copy that actually holds data
///   fills gaps — never overwrite a present value with null.
class ConflictResolver {
  ConflictResolver._();

  static EmergencyModel resolveEmergencyConflict({
    required EmergencyModel local,
    required EmergencyModel remote,
  }) {
    final remoteResolved = remote.status != EmergencyStatus.active;

    final mergedStatus = remoteResolved ? remote.status : local.status;
    final resolvedAt = remote.resolvedAt ?? local.resolvedAt;

    return EmergencyModel(
      emergencyId: local.emergencyId,
      userId: local.userId,
      status: mergedStatus,
      triggeredBy: remote.triggeredBy != EmergencyTrigger.manual
          ? remote.triggeredBy
          : local.triggeredBy,
      lat: local.lat ?? remote.lat,
      lng: local.lng ?? remote.lng,
      audioUrl: local.audioUrl ?? remote.audioUrl,
      videoUrl: local.videoUrl ?? remote.videoUrl,
      livestreamUrl: local.livestreamUrl ?? remote.livestreamUrl,
      createdAt: local.createdAt.isBefore(remote.createdAt)
          ? local.createdAt
          : remote.createdAt,
      resolvedAt: resolvedAt,
    );
  }

  /// De-duplicates a queue by [EmergencyModel.emergencyId], keeping the most
  /// recently created entry.
  static List<EmergencyModel> dedupeEmergencies(List<EmergencyModel> items) {
    final byId = <String, EmergencyModel>{};
    for (final item in items) {
      final existing = byId[item.emergencyId];
      if (existing == null || item.createdAt.isAfter(existing.createdAt)) {
        byId[item.emergencyId] = item;
      }
    }
    return byId.values.toList();
  }
}
