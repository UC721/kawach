import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class Helpers {
  // ── Distance formatting ──────────────────────────────────────
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // ── Time formatting ──────────────────────────────────────────
  static String formatTimestamp(DateTime dt) {
    return DateFormat('dd MMM yyyy · HH:mm').format(dt);
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Location helpers ─────────────────────────────────────────
  static String formatLatLng(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  static double distanceBetween(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // ── Phone number formatting ──────────────────────────────────
  static String maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}';
  }

  // ── Safe logging (debug only) ────────────────────────────────
  static void log(String message) {
    if (kDebugMode) {
      print('[KAWACH] $message');
    }
  }

  // ── Risk color ───────────────────────────────────────────────
  static int riskToHue(double score) {
    // 0–4 = green, 4–7 = orange, 7–10 = red
    if (score < 4) return 120; // green hue
    if (score < 7) return 30;  // orange hue
    return 0;                  // red hue
  }

  // ── Emergency trigger label ──────────────────────────────────
  static String triggerLabel(String trigger) {
    switch (trigger) {
      case 'manual':
        return 'Manual SOS';
      case 'shake':
        return 'Shake Detection';
      case 'voice':
        return 'Voice Command';
      case 'panic':
        return 'Panic Detection';
      case 'snatch':
        return 'Phone Snatch';
      case 'safeWalkTimeout':
        return 'Safe Walk Timer';
      case 'countdown':
        return 'Countdown Timer';
      default:
        return trigger.toUpperCase();
    }
  }
}
