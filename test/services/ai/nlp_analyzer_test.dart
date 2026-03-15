import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/ai/nlp_analyzer.dart';

void main() {
  late NlpAnalyzer analyzer;

  setUp(() {
    analyzer = NlpAnalyzer();
  });

  group('NlpAnalyzer', () {
    test('empty text returns NONE', () {
      final result = analyzer.analyzeSpeech('');
      expect(result.label, 'NONE');
      expect(result.confidence, 0.0);
    });

    test('detects English panic phrases', () {
      final result = analyzer.analyzeSpeech('help me please');
      expect(result.label, 'PANIC');
      expect(result.confidence, greaterThan(0.5));
    });

    test('detects Hindi panic phrases', () {
      final result = analyzer.analyzeSpeech('bachao mujhe bachao');
      expect(result.label, 'PANIC');
    });

    test('isPanic returns true for high-confidence panic', () {
      expect(analyzer.isPanic('help me please stop'), isTrue);
    });

    test('isPanic returns false for normal speech', () {
      expect(analyzer.isPanic('the weather is nice today'), isFalse);
    });

    test('repetition boosts intensity', () {
      final single = analyzer.analyzeSpeech('help');
      final repeated = analyzer.analyzeSpeech('help help help help');
      expect(repeated.score, greaterThanOrEqualTo(single.score));
    });

    test('returns distress for moderate keywords', () {
      final result = analyzer.analyzeSpeech('stop');
      expect(['ALERT', 'DISTRESS', 'PANIC'], contains(result.label));
    });

    test('metadata includes matched keywords', () {
      final result = analyzer.analyzeSpeech('help me bachao');
      final keywords =
          result.metadata['matched_keywords'] as List<dynamic>;
      expect(keywords, contains('help me'));
      expect(keywords, contains('bachao'));
    });
  });
}
