/// Unified data model for AI predictions across all KAWACH modules.
class AIPrediction {
  /// Module that generated this prediction (e.g. 'threat', 'nlp', 'route').
  final String module;

  /// Primary label produced by the model (e.g. 'HIGH_THREAT', 'panic').
  final String label;

  /// Confidence score in the range [0.0, 1.0].
  final double confidence;

  /// Numeric risk/severity score in the range [0.0, 10.0].
  final double score;

  /// Additional metadata key-value pairs.
  final Map<String, dynamic> metadata;

  /// When the prediction was produced.
  final DateTime timestamp;

  AIPrediction({
    required this.module,
    required this.label,
    required this.confidence,
    this.score = 0.0,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIPrediction.fromMap(Map<String, dynamic> data) {
    return AIPrediction(
      module: data['module'] ?? '',
      label: data['label'] ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'module': module,
        'label': label,
        'confidence': confidence,
        'score': score,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.5;

  @override
  String toString() =>
      'AIPrediction($module: $label @ ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Classification of threat severity levels.
enum ThreatLevel { safe, low, moderate, high, critical }

/// Scene environment classification.
enum SceneType { indoor, outdoor, crowded, isolated, vehicle, unknown }

/// Behavioral pattern types detected by the AI.
enum BehaviorPattern {
  normal,
  erratic,
  stationary,
  fleeing,
  followedPattern,
  unknown,
}
