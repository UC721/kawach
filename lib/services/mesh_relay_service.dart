import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/emergency_model.dart';
import '../models/mesh_packet_model.dart';
import '../models/nearby_alert_model.dart';
import '../utils/constants.dart';
import 'payload_cipher.dart';
import 'sos_queue_manager.dart';

class MeshRelayService extends ChangeNotifier {
  MeshRelayService({
    SosQueueManager? queueManager,
  }) : _queueManager = queueManager ?? SosQueueManager.instance;

  static const MethodChannel _channel = MethodChannel('kawach/mesh');

  final SupabaseClient _db = Supabase.instance.client;
  final SosQueueManager _queueManager;
  final Uuid _uuid = const Uuid();

  bool _isRelaying = false;
  bool get isRelaying => _isRelaying;

  Future<void> broadcastEmergency({
    required EmergencyModel emergency,
    required String userName,
  }) async {
    final packet = MeshPacketModel(
      packetId: _uuid.v4(),
      emergencyId: emergency.emergencyId,
      userId: emergency.userId,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(minutes: AppThresholds.meshPacketTtlMinutes),
      ),
      lat: emergency.lat,
      lng: emergency.lng,
      relaySource: 'supabase',
      payload: PayloadCipher.encryptObject(
        {
          'emergencyId': emergency.emergencyId,
          'userId': emergency.userId,
          'userName': userName,
          'lat': emergency.lat,
          'lng': emergency.lng,
          'createdAt': emergency.createdAt.toIso8601String(),
          'status': emergency.status.name,
        },
        scope: emergency.emergencyId,
      ),
    );

    try {
      await _db.from(FSCollection.meshPackets).insert(packet.toMap());
    } catch (_) {
      await _queueManager.enqueueMeshPacket(packet);
    }

    try {
      await _channel.invokeMethod<void>('startRelay', {
        'packet': jsonEncode(packet.toMap()),
      });
      _isRelaying = true;
      notifyListeners();
    } catch (error) {
      debugPrint('MeshRelayService.startRelay failed: $error');
    }
  }

  Future<void> stopRelay() async {
    try {
      await _channel.invokeMethod<void>('stopRelay');
    } catch (error) {
      debugPrint('MeshRelayService.stopRelay failed: $error');
    } finally {
      _isRelaying = false;
      notifyListeners();
    }
  }

  Stream<List<NearbyAlertModel>> streamNearbyAlerts({
    required String volunteerId,
    required double currentLat,
    required double currentLng,
  }) {
    return _db
        .from(FSCollection.volunteerAlerts)
        .stream(primaryKey: ['alert_id'])
        .eq('volunteer_id', volunteerId)
        .map((rows) {
      return rows
          .map(NearbyAlertModel.fromMap)
          .where((alert) {
            if (!alert.isActive) {
              return false;
            }
            if (alert.lat == null || alert.lng == null) {
              return true;
            }
            return Geolocator.distanceBetween(
                  currentLat,
                  currentLng,
                  alert.lat!,
                  alert.lng!,
                ) <=
                AppThresholds.meshRelayRadiusMeters;
          })
          .toList()
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    });
  }

  Future<void> acknowledgePacket({
    required String packetId,
    required String volunteerId,
  }) async {
    await _db.from(FSCollection.meshAcks).insert({
      'packet_id': packetId,
      'volunteer_id': volunteerId,
      'acknowledged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> flushQueuedPackets() async {
    final queuedPackets = await _queueManager.takeQueuedMeshPackets();
    if (queuedPackets.isEmpty) {
      return;
    }

    final failed = <MeshPacketModel>[];
    for (final packet in queuedPackets) {
      try {
        await _db.from(FSCollection.meshPackets).insert(packet.toMap());
      } catch (_) {
        failed.add(packet);
      }
    }

    await _queueManager.replaceQueuedMeshPackets(failed);
  }
}
