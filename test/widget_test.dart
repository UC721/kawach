import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kawach/models/emergency_model.dart';
import 'package:kawach/models/location_update_model.dart';
import 'package:kawach/models/mesh_packet_model.dart';
import 'package:kawach/models/user_model.dart';
import 'package:kawach/services/sos_queue_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('EmergencyModel', () {
    test('round-trips through toMap/fromMap', () {
      final created = DateTime.utc(2026, 1, 15, 9, 30);
      final original = EmergencyModel(
        emergencyId: 'emg-1',
        userId: 'usr-1',
        status: EmergencyStatus.active,
        triggeredBy: EmergencyTrigger.shake,
        lat: 28.6139,
        lng: 77.2090,
        createdAt: created,
      );

      final restored = EmergencyModel.fromMap(original.toMap());

      expect(restored.emergencyId, 'emg-1');
      expect(restored.userId, 'usr-1');
      expect(restored.status, EmergencyStatus.active);
      expect(restored.triggeredBy, EmergencyTrigger.shake);
      expect(restored.lat, 28.6139);
      expect(restored.lng, 77.2090);
      expect(restored.createdAt, created);
    });

    test('fromMap tolerates snake_case Supabase payload', () {
      final restored = EmergencyModel.fromMap(<String, dynamic>{
        'emergency_id': 'emg-2',
        'user_id': 'usr-2',
        'status': 'resolved',
        'triggered_by': 'panic',
        'lat': 12.97,
        'lng': 77.59,
        'created_at': '2026-02-01T10:00:00.000Z',
        'resolved_at': '2026-02-01T10:05:00.000Z',
      });

      expect(restored.emergencyId, 'emg-2');
      expect(restored.status, EmergencyStatus.resolved);
      expect(restored.triggeredBy, EmergencyTrigger.panic);
      expect(restored.resolvedAt, DateTime.utc(2026, 2, 1, 10, 5));
    });

    test('copyWith updates only provided fields', () {
      final base = EmergencyModel(
        emergencyId: 'emg-3',
        userId: 'usr-3',
        status: EmergencyStatus.active,
        triggeredBy: EmergencyTrigger.manual,
        createdAt: DateTime.utc(2026, 3, 1),
      );

      final resolved = base.copyWith(
        status: EmergencyStatus.resolved,
        resolvedAt: DateTime.utc(2026, 3, 1, 1),
      );

      expect(resolved.status, EmergencyStatus.resolved);
      expect(resolved.triggeredBy, EmergencyTrigger.manual);
      expect(resolved.resolvedAt, DateTime.utc(2026, 3, 1, 1));
      expect(base.status, EmergencyStatus.active);
    });
  });

  group('LocationUpdateModel', () {
    test('round-trips through toMap/fromMap', () {
      final recorded = DateTime.utc(2026, 4, 1, 12, 0);
      final original = LocationUpdateModel(
        emergencyId: 'emg-1',
        userId: 'usr-1',
        lat: 19.0760,
        lng: 72.8777,
        recordedAt: recorded,
        speed: 1.5,
        accuracy: 6.0,
      );

      final restored = LocationUpdateModel.fromMap(original.toMap());

      expect(restored.emergencyId, 'emg-1');
      expect(restored.lat, 19.0760);
      expect(restored.lng, 72.8777);
      expect(restored.speed, 1.5);
      expect(restored.accuracy, 6.0);
      expect(restored.recordedAt, recorded);
      expect(restored.source, 'device');
    });
  });

  group('UserModel', () {
    test('round-trips through toMap/fromMap', () {
      final original = UserModel(
        userId: 'usr-9',
        name: 'Aisha',
        phone: '+919876543210',
        email: 'aisha@example.com',
        guardianIds: const ['usr-1', 'usr-2'],
        createdAt: DateTime.utc(2026, 5, 1),
      );

      final restored = UserModel.fromMap(original.toMap());

      expect(restored.userId, 'usr-9');
      expect(restored.name, 'Aisha');
      expect(restored.guardianIds, const ['usr-1', 'usr-2']);
      expect(restored.createdAt, DateTime.utc(2026, 5, 1));
    });
  });

  group('SosQueueManager (offline pipeline)', () {
    test('enqueues and takes emergencies', () async {
      final queue = SosQueueManager.instance;
      final emergency = EmergencyModel(
        emergencyId: 'emg-q1',
        userId: 'usr-q1',
        status: EmergencyStatus.active,
        triggeredBy: EmergencyTrigger.voice,
        lat: 20.59,
        lng: 78.96,
        createdAt: DateTime.utc(2026, 6, 1),
      );

      await queue.initialize();
      await queue.enqueueEmergency(emergency);

      final queued = await queue.takeQueuedEmergencies();
      expect(queued, hasLength(1));
      expect(queued.first.emergencyId, 'emg-q1');

      await queue.replaceQueuedEmergencies(<EmergencyModel>[]);
      expect(await queue.takeQueuedEmergencies(), isEmpty);
    });

    test('snapshot reports pending item counts', () async {
      final queue = SosQueueManager.instance;
      final location = LocationUpdateModel(
        emergencyId: 'emg-q2',
        userId: 'usr-q2',
        lat: 20.59,
        lng: 78.96,
        recordedAt: DateTime.utc(2026, 6, 2),
      );

      await queue.initialize();
      await queue.enqueueLocation(location);

      final snapshot = await queue.snapshot();
      expect(snapshot.emergencies, 0);
      expect(snapshot.locations, 1);
      expect(snapshot.evidence, 0);
      expect(snapshot.meshPackets, 0);
    });

    test('caches and clears the active emergency for restart recovery',
        () async {
      final queue = SosQueueManager.instance;
      final emergency = EmergencyModel(
        emergencyId: 'emg-q3',
        userId: 'usr-q3',
        status: EmergencyStatus.active,
        triggeredBy: EmergencyTrigger.manual,
        createdAt: DateTime.utc(2026, 6, 3),
      );

      await queue.initialize();
      await queue.cacheActiveEmergency(emergency);

      final cached = await queue.getCachedActiveEmergency();
      expect(cached, isNotNull);
      expect(cached!.emergencyId, 'emg-q3');
      expect(cached.status, EmergencyStatus.active);

      await queue.clearCachedActiveEmergency();
      expect(await queue.getCachedActiveEmergency(), isNull);
    });

    test('mesh packet queue round-trips', () async {
      final queue = SosQueueManager.instance;
      await queue.initialize();
      await queue.enqueueMeshPacket(
        MeshPacketModel(
          packetId: 'pkt-1',
          emergencyId: 'emg-q4',
          userId: 'usr-q4',
          payload: '{"hello":"mesh"}',
          createdAt: DateTime.utc(2026, 6, 4),
          expiresAt: DateTime.utc(2026, 6, 4, 0, 20),
        ),
      );

      final packets = await queue.takeQueuedMeshPackets();
      expect(packets, hasLength(1));
      expect(packets.first.packetId, 'pkt-1');
    });
  });
}
