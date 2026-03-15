import '../../models/ai_prediction_model.dart';

/// Natural language analysis for voice and text input.
///
/// Performs panic phrase detection with confidence scoring, sentiment
/// intensity estimation, and multi-language keyword matching.
class NlpAnalyzer {
  /// Weighted panic keywords.  Higher weight = stronger panic indicator.
  static const Map<String, double> _panicKeywords = {
    // English
    'help': 0.8,
    'help me': 1.0,
    'stop': 0.6,
    'leave me alone': 0.9,
    'please stop': 0.85,
    'let me go': 0.9,
    'save me': 1.0,
    'somebody help': 1.0,
    'call the police': 0.95,
    'fire': 0.5,
    'danger': 0.7,
    'emergency': 0.85,
    'attack': 0.9,
    'follow': 0.4,
    'scared': 0.6,
    'threatening': 0.7,
    // Hindi / Urdu
    'bachao': 1.0,
    'chhodo': 0.9,
    'madad': 0.95,
    'madad karo': 1.0,
    'mujhe bachao': 1.0,
    'koi hai': 0.7,
    'police bulao': 0.95,
    'hatiye': 0.6,
  };

  /// Distress intensity multipliers based on speech features.
  static const Map<String, double> _intensityIndicators = {
    'please': 0.1,
    '!': 0.15,
    'now': 0.1,
    'hurry': 0.15,
    'quick': 0.1,
    'fast': 0.1,
    'run': 0.1,
  };

  /// Analyse recognised speech text for panic indicators.
  AIPrediction analyzeSpeech(String text) {
    if (text.isEmpty) {
      return AIPrediction(
        module: 'nlp_analyzer',
        label: 'NONE',
        confidence: 0.0,
        score: 0.0,
        metadata: {'matched_keywords': <String>[]},
      );
    }

    final lower = text.toLowerCase().trim();
    double maxWeight = 0.0;
    final matchedKeywords = <String>[];

    // Check all panic keywords.
    for (final entry in _panicKeywords.entries) {
      if (lower.contains(entry.key)) {
        matchedKeywords.add(entry.key);
        if (entry.value > maxWeight) maxWeight = entry.value;
      }
    }

    // Intensity modifier based on urgency words.
    double intensityBoost = 0.0;
    for (final entry in _intensityIndicators.entries) {
      if (lower.contains(entry.key)) {
        intensityBoost += entry.value;
      }
    }

    // Word repetition detection (e.g. "help help help").
    final words = lower.split(RegExp(r'\s+'));
    final wordCounts = <String, int>{};
    for (final w in words) {
      wordCounts[w] = (wordCounts[w] ?? 0) + 1;
    }
    final maxRepeat = wordCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxRepeat >= 3) intensityBoost += 0.2;

    final rawScore = (maxWeight + intensityBoost).clamp(0.0, 1.0);
    final confidence = _computeConfidence(matchedKeywords.length, maxWeight, words.length);

    final label = rawScore >= 0.7
        ? 'PANIC'
        : rawScore >= 0.4
            ? 'DISTRESS'
            : rawScore > 0
                ? 'ALERT'
                : 'NONE';

    return AIPrediction(
      module: 'nlp_analyzer',
      label: label,
      confidence: confidence,
      score: rawScore * 10.0,
      metadata: {
        'matched_keywords': matchedKeywords,
        'intensity_boost': intensityBoost,
        'max_repeat': maxRepeat,
        'word_count': words.length,
      },
    );
  }

  /// Quick boolean check – suitable for real-time callback.
  bool isPanic(String text) {
    final prediction = analyzeSpeech(text);
    return prediction.label == 'PANIC' && prediction.confidence >= 0.6;
  }

  double _computeConfidence(int matchCount, double maxWeight, int totalWords) {
    if (matchCount == 0) return 0.0;
    // More matches and higher individual weights → higher confidence.
    final matchFactor = (matchCount / 3.0).clamp(0.0, 1.0);
    final weightFactor = maxWeight;
    // Short utterances with panic words are more trustworthy.
    final brevityFactor = totalWords <= 5 ? 0.1 : 0.0;
    return (matchFactor * 0.4 + weightFactor * 0.5 + brevityFactor).clamp(0.0, 1.0);
  }
}
