import 'dart:typed_data';
import 'ble_mesh_service.dart';
import 'wifi_direct_service.dart';
import 'dedup_cache.dart';

// ============================================================
// MeshRouter – Multi-hop message routing across mesh peers
// ============================================================

/// Routes SOS messages across BLE and Wi-Fi Direct transports.
///
/// Implements TTL-based flooding with deduplication to prevent
/// broadcast storms while maximising delivery probability.
class MeshRouter {
  final BleMeshService _bleMesh;
  final WifiDirectService _wifiDirect;
  final DedupCache _dedupCache;

  MeshRouter({
    required BleMeshService bleMesh,
    required WifiDirectService wifiDirect,
    DedupCache? dedupCache,
  })  : _bleMesh = bleMesh,
        _wifiDirect = wifiDirect,
        _dedupCache = dedupCache ?? DedupCache();

  /// Route an SOS payload to all reachable peers.
  ///
  /// Returns the total number of successful relays across all transports.
  Future<int> routeMessage(String messageId, Uint8List payload,
      {int ttl = 5}) async {
    if (_dedupCache.contains(messageId)) return 0;
    _dedupCache.add(messageId);

    if (ttl <= 0) return 0;

    var totalRelays = 0;

    // Try BLE mesh first (lower power)
    totalRelays += await _bleMesh.broadcastSos(payload, ttl: ttl - 1);

    // Supplement with Wi-Fi Direct for higher bandwidth
    try {
      await _wifiDirect.broadcastToGroup(payload);
      totalRelays += _wifiDirect.peers.length;
    } catch (_) {
      // Wi-Fi Direct may not be available
    }

    return totalRelays;
  }

  /// Start both mesh transports.
  Future<void> startMesh() async {
    await _bleMesh.startScanning();
    await _wifiDirect.discoverPeers();
  }

  /// Stop both mesh transports.
  Future<void> stopMesh() async {
    await _bleMesh.stopScanning();
    await _wifiDirect.disconnect();
  }
}
