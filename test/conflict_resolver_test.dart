import 'package:flutter_test/flutter_test.dart';

import 'package:kawach/models/emergency_model.dart';
import 'package:kawach/services/conflict_resolver.dart';

EmergencyModel _emergency({
  required String id,
  required EmergencyStatus status,
  EmergencyTrigger trigger = EmergencyTrigger.manual,
  double? lat,
  double? lng,
  String? audioUrl,
  String? videoUrl,
  DateTime? createdAt,
  DateTime? resolvedAt,
}) {
  return EmergencyModel(
    emergencyId: id,
    userId: 'usr',
    status: status,
    triggeredBy: trigger,
    lat: lat,
    lng: lng,
    audioUrl: audioUrl,
    videoUrl: videoUrl,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    resolvedAt: resolvedAt,
  );
}

void main() {
  group('ConflictResolver.resolveEmergencyConflict', () {
    test('server resolution wins over a stale local active copy', () {
      final local = _emergency(
        id: 'emg-c1',
        status: EmergencyStatus.active,
        createdAt: DateTime.utc(2026, 1, 1, 8),
      );
      final remote = _emergency(
        id: 'emg-c1',
        status: EmergencyStatus.resolved,
        createdAt: DateTime.utc(2026, 1, 1, 7),
        resolvedAt: DateTime.utc(2026, 1, 1, 9),
      );

      final merged = ConflictResolver.resolveEmergencyConflict(
          local: local, remote: remote);

      expect(merged.status, EmergencyStatus.resolved);
      expect(merged.resolvedAt, DateTime.utc(2026, 1, 1, 9));
    });

    test('local fills payload gaps the server never received', () {
      final local = _emergency(
        id: 'emg-c2',
        status: EmergencyStatus.active,
        lat: 28.6139,
        lng: 77.2090,
        audioUrl: 'https://bucket/audio.mp3',
        createdAt: DateTime.utc(2026, 1, 1, 8),
      );
      final remote = _emergency(
        id: 'emg-c2',
        status: EmergencyStatus.active,
        createdAt: DateTime.utc(2026, 1, 1, 7),
      );

      final merged = ConflictResolver.resolveEmergencyConflict(
          local: local, remote: remote);

      expect(merged.lat, 28.6139);
      expect(merged.lng, 77.2090);
      expect(merged.audioUrl, 'https://bucket/audio.mp3');
      expect(merged.videoUrl, isNull);
    });

    test('creation timestamp is never pushed forward by a later local copy',
        () {
      final local = _emergency(
        id: 'emg-c3',
        status: EmergencyStatus.active,
        createdAt: DateTime.utc(2026, 1, 1, 8),
      );
      final remote = _emergency(
        id: 'emg-c3',
        status: EmergencyStatus.active,
        createdAt: DateTime.utc(2026, 1, 1, 6),
      );

      final merged = ConflictResolver.resolveEmergencyConflict(
          local: local, remote: remote);

      expect(merged.createdAt, DateTime.utc(2026, 1, 1, 6));
    });

    test('non-manual trigger on either side survives the merge', () {
      final local = _emergency(
        id: 'emg-c4',
        status: EmergencyStatus.active,
        trigger: EmergencyTrigger.shake,
        createdAt: DateTime.utc(2026, 1, 1, 8),
      );
      final remote = _emergency(
        id: 'emg-c4',
        status: EmergencyStatus.active,
        createdAt: DateTime.utc(2026, 1, 1, 7),
      );

      final merged = ConflictResolver.resolveEmergencyConflict(
          local: local, remote: remote);

      expect(merged.triggeredBy, EmergencyTrigger.shake);
    });
  });

  group('ConflictResolver.dedupeEmergencies', () {
    test('keeps the newest copy per emergency id', () {
      final older = _emergency(
        id: 'emg-d1',
        status: EmergencyStatus.active,
        createdAt: DateTime.utc(2026, 1, 1, 8),
      );
      final newer = _emergency(
        id: 'emg-d1',
        status: EmergencyStatus.resolved,
        createdAt: DateTime.utc(2026, 1, 1, 10),
      );

      final deduped = ConflictResolver.dedupeEmergencies([older, newer]);

      expect(deduped, hasLength(1));
      expect(deduped.first.status, EmergencyStatus.resolved);
    });
  });
}
