import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  MockChatRepository([List<ChatMessage> messages = const []])
    : _messages = {for (final m in messages) '${m.caseId}:${m.id}': m};
  final Map<String, ChatMessage> _messages;
  @override
  Future<List<ChatMessage>> fetchMessages(String caseId) async {
    final result = _messages.values.where((m) => m.caseId == caseId).toList()
      ..sort((a, b) {
        final time = a.createdAt.compareTo(b.createdAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
    return List.unmodifiable(result);
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    final key = '${message.caseId}:${message.id}';
    final existing = _messages[key];
    if (existing != null && existing != message) {
      throw StateError('Conflicting message ID');
    }
    _messages[key] = message;
    return message;
  }
}
