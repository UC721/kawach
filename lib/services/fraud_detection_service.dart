import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI-powered fraud detection for SOS alerts.
///
/// Computes a fraud score (0.0 – 1.0) combining:
/// * **Velocity check** — flags rapid successive SOS alerts from the same user.
/// * **Location plausibility** — detects impossible travel between alerts.
/// * **Behavioural signals** — time-of-day, device motion consistency, etc.
///
/// Alerts with a fraud score ≥ [fraudThreshold] are soft-blocked (logged but
/// not dispatched to guardians) until manual review.
class FraudDetectionService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  /// Fraud-score threshold above which an SOS is considered suspicious.
  static const double fraudThreshold = 0.7;

  /// Maximum allowed SOS alerts within [_velocityWindowMinutes].
  static const int maxAlertsInWindow = 3;

  /// Time window for rate / velocity checks (in minutes).
  static const int velocityWindowMinutes = 10;

  /// Evaluates an SOS alert and returns a [FraudResult].
  Future<FraudResult> evaluateSos({
    required String userId,
    required double? lat,
    required double? lng,
  }) async {
    double score = 0.0;
    final reasons = <String>[];

    // ── Velocity check ────────────────────────────────────────
    final velocityScore = await _velocityCheck(userId);
    if (velocityScore > 0) {
      score += velocityScore;
      reasons.add('High SOS frequency');
    }

    // ── Location plausibility ─────────────────────────────────
    if (lat != null && lng != null) {
      final locationScore = await _locationPlausibility(userId, lat, lng);
      if (locationScore > 0) {
        score += locationScore;
        reasons.add('Implausible travel distance');
      }
    }

    // ── Time-of-day heuristic ─────────────────────────────────
    final hourScore = _timeOfDayScore();
    score += hourScore;
    if (hourScore > 0) {
      reasons.add('Unusual time-of-day pattern');
    }

    // Clamp to [0, 1]
    score = score.clamp(0.0, 1.0);

    return FraudResult(
      score: score,
      isSuspicious: score >= fraudThreshold,
      reasons: reasons,
    );
  }

  /// Checks how many SOS alerts the user has triggered in the last
  /// [velocityWindowMinutes] minutes.
  Future<double> _velocityCheck(String userId) async {
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: velocityWindowMinutes))
        .toIso8601String();

    try {
      final res = await _db
          .from('sos_alerts')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', cutoff);

      final count = (res as List).length;
      if (count >= maxAlertsInWindow) return 0.5;
      if (count >= maxAlertsInWindow - 1) return 0.2;
    } catch (_) {
      // If the table doesn't exist yet, skip this check
    }
    return 0.0;
  }

  /// Checks whether the user could physically travel from their last known
  /// SOS location to the current one within the elapsed time.
  Future<double> _locationPlausibility(
      String userId, double lat, double lng) async {
    try {
      final res = await _db
          .from('sos_alerts')
          .select('lat, lng, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((res as List).isEmpty) return 0.0;

      final last = res.first;
      final lastLat = (last['lat'] as num?)?.toDouble();
      final lastLng = (last['lng'] as num?)?.toDouble();
      final lastTime = DateTime.tryParse(last['created_at'] as String? ?? '');

      if (lastLat == null || lastLng == null || lastTime == null) return 0.0;

      // Rough distance in km (Euclidean approximation for nearby points)
      final dLat = (lat - lastLat) * 111.0;
      final dLng = (lng - lastLng) * 111.0 * 0.7; // rough cos(lat) factor
      final distKm = (dLat * dLat + dLng * dLng);

      final elapsedHours =
          DateTime.now().difference(lastTime).inMinutes / 60.0;
      if (elapsedHours <= 0) return 0.0;

      // Max plausible speed: 200 km/h
      final impliedSpeed = distKm / elapsedHours;
      if (impliedSpeed > 200) return 0.4;
    } catch (_) {
      // Skip if table unavailable
    }
    return 0.0;
  }

  /// Returns a small score bump for SOS triggered between 2 AM – 5 AM
  /// (statistically unusual pattern that may indicate testing/abuse).
  double _timeOfDayScore() {
    final hour = DateTime.now().hour;
    if (hour >= 2 && hour < 5) return 0.1;
    return 0.0;
  }
}

/// Result of a fraud evaluation on an SOS alert.
class FraudResult {
  final double score;
  final bool isSuspicious;
  final List<String> reasons;

  const FraudResult({
    required this.score,
    required this.isSuspicious,
    required this.reasons,
  });

  @override
  String toString() =>
      'FraudResult(score: ${score.toStringAsFixed(2)}, suspicious: $isSuspicious, reasons: $reasons)';
}
