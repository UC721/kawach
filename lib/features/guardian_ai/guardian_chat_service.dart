import 'dart:async';

// ============================================================
// GuardianChatService – AI safety companion (Module 11)
// ============================================================

/// Provides a conversational AI interface for safety guidance.
///
/// Uses intent classification to understand user queries and
/// provide context-appropriate safety advice.
class GuardianChatService {
  final List<ChatMessage> _history = [];
  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Send a user message and get an AI response.
  Future<ChatMessage> sendMessage(String userMessage) async {
    final userMsg = ChatMessage(
      role: ChatRole.user,
      content: userMessage,
      timestamp: DateTime.now(),
    );
    _history.add(userMsg);

    // In production: send to Supabase Edge Function or on-device model
    final response = _generateSafetyResponse(userMessage);
    final aiMsg = ChatMessage(
      role: ChatRole.assistant,
      content: response,
      timestamp: DateTime.now(),
    );
    _history.add(aiMsg);

    return aiMsg;
  }

  String _generateSafetyResponse(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('follow') || lower.contains('stalker')) {
      return 'If you feel you are being followed, walk toward a well-lit, '
          'populated area. Consider activating Safe Walk mode, and I can '
          'guide you to the nearest safe zone.';
    }
    if (lower.contains('unsafe') || lower.contains('danger')) {
      return 'Your safety is the priority. You can activate SOS by pressing '
          'the SOS button or using the silent trigger (press power button 5 '
          'times). I can also plan a safe route for you.';
    }
    if (lower.contains('route') || lower.contains('walk')) {
      return 'I can help you find the safest route. Go to Safe Route on the '
          'main menu to see safety-scored paths to your destination.';
    }
    return 'I\'m here to help keep you safe. You can ask me about safe routes, '
        'emergency procedures, or activating safety features.';
  }

  void clearHistory() => _history.clear();
}

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

enum ChatRole { user, assistant, system }
