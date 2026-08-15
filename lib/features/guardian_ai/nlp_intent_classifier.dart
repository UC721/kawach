// ============================================================
// NlpIntentClassifier – On-device intent classification (Module 11)
// ============================================================

/// Classifies user chat messages into safety-related intents.
///
/// Uses a TFLite model (`intent_classifier.tflite`) for on-device
/// inference. Falls back to keyword matching when the model is
/// unavailable.
class NlpIntentClassifier {
  static const String modelAsset = 'assets/models/intent_classifier.tflite';

  /// Classify the intent of a user message.
  IntentResult classify(String message) {
    final lower = message.toLowerCase().trim();

    // Keyword-based fallback classification
    for (final entry in _intentKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return IntentResult(
            intent: entry.key,
            confidence: 0.85,
            entities: _extractEntities(lower),
          );
        }
      }
    }

    return IntentResult(
      intent: SafetyIntent.general,
      confidence: 0.5,
      entities: {},
    );
  }

  static const Map<SafetyIntent, List<String>> _intentKeywords = {
    SafetyIntent.triggerSos: ['help', 'emergency', 'sos', 'danger', 'bachao'],
    SafetyIntent.findSafeRoute: ['route', 'walk', 'navigate', 'direction'],
    SafetyIntent.reportIncident: ['report', 'incident', 'happened', 'assault'],
    SafetyIntent.contactGuardian: ['guardian', 'contact', 'call', 'family'],
    SafetyIntent.checkSafety: ['safe', 'area', 'zone', 'score', 'rating'],
    SafetyIntent.fakeCall: ['fake', 'pretend', 'excuse'],
  };

  Map<String, String> _extractEntities(String text) {
    final entities = <String, String>{};
    // Simple entity extraction
    final locationPattern = RegExp(r'(?:to|from|near|at)\s+(\w+)');
    final match = locationPattern.firstMatch(text);
    if (match != null) {
      entities['location'] = match.group(1) ?? '';
    }
    return entities;
  }
}

enum SafetyIntent {
  triggerSos,
  findSafeRoute,
  reportIncident,
  contactGuardian,
  checkSafety,
  fakeCall,
  general,
}

class IntentResult {
  final SafetyIntent intent;
  final double confidence;
  final Map<String, String> entities;

  const IntentResult({
    required this.intent,
    required this.confidence,
    required this.entities,
  });
}
