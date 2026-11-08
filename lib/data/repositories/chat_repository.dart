import '../models/chat_message.dart';

abstract interface class ChatRepository {
  Future<List<ChatMessage>> fetchMessages(String caseId);

  /// Retrying the same message ID/payload is idempotent. Failure leaves data unchanged.
  Future<ChatMessage> sendMessage(ChatMessage message);
}
