import 'dart:math';

/// Anonymizes precise GPS coordinates to geohash-5 precision (~5 km²) for
/// sharing with CrowdShield peers.
///
/// A geohash-5 cell is approximately 4.9 km × 4.9 km, which provides
/// sufficient precision for nearby-peer discovery without revealing an exact
/// location.
class LocationAnonymizer {
  static const int _defaultPrecision = 5;
  static const String _base32Chars = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Returns a geohash string at [precision] characters (default 5 ≈ 5 km²).
  static String toGeohash(
    double latitude,
    double longitude, {
    int precision = _defaultPrecision,
  }) {
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    bool isLng = true;
    int bit = 0;
    int ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isLng) {
        final mid = (lngMin + lngMax) / 2;
        if (longitude >= mid) {
          ch |= (1 << (4 - bit));
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      isLng = !isLng;
      bit++;

      if (bit == 5) {
        buffer.write(_base32Chars[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Decodes a geohash back to the centre point of its bounding box.
  static ({double latitude, double longitude}) fromGeohash(String geohash) {
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    bool isLng = true;

    for (final c in geohash.split('')) {
      final idx = _base32Chars.indexOf(c);
      if (idx < 0) continue;
      for (int bit = 4; bit >= 0; bit--) {
        if (isLng) {
          final mid = (lngMin + lngMax) / 2;
          if ((idx >> bit) & 1 == 1) {
            lngMin = mid;
          } else {
            lngMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if ((idx >> bit) & 1 == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isLng = !isLng;
      }
    }

    return (
      latitude: (latMin + latMax) / 2,
      longitude: (lngMin + lngMax) / 2,
    );
  }

  /// Returns true if two coordinates fall within the same geohash-5 cell.
  static bool isSameCell(
    double lat1,
    double lng1,
    double lat2,
    double lng2, {
    int precision = _defaultPrecision,
  }) {
    return toGeohash(lat1, lng1, precision: precision) ==
        toGeohash(lat2, lng2, precision: precision);
  }

  /// Returns the approximate area (in km²) of a geohash cell at the given
  /// [precision].
  static double cellAreaKm2(int precision) {
    // Each geohash character halves the search space 5 times (alternating
    // lat/lng).  Approximate cell dimensions:
    const latHeight = 180.0; // degrees
    const lngWidth = 360.0;  // degrees
    // Each character contributes ~2.5 bits to each axis.
    final latCells = pow(2, (precision * 5 / 2).floor());
    final lngCells = pow(2, (precision * 5 / 2).ceil());
    final cellLatDeg = latHeight / latCells;
    final cellLngDeg = lngWidth / lngCells;
    // 1 degree latitude ≈ 111 km, longitude varies by cos(lat), assume ~79 km
    return (cellLatDeg * 111) * (cellLngDeg * 79);
  }
}
