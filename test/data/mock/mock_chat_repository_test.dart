import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/chat_message.dart';
import 'package:gavel/data/mock/mock_chat_repository.dart';

void main() {
  test(
    'sends are idempotent, chronological, case-isolated and immutable',
    () async {
      final repo = MockChatRepository();
      final first = ChatMessage(
        id: 'a',
        caseId: 'c',
        senderId: 's',
        text: 'First',
        createdAt: DateTime(2026),
      );
      final second = ChatMessage(
        id: 'b',
        caseId: 'c',
        senderId: 's',
        text: 'Second',
        createdAt: DateTime(2026, 1, 2),
      );
      await repo.sendMessage(second);
      await repo.sendMessage(first);
      await repo.sendMessage(first);
      final messages = await repo.fetchMessages('c');
      expect(messages, [first, second]);
      expect(await repo.fetchMessages('other'), isEmpty);
      await expectLater(
        repo.sendMessage(first.copyWith(text: 'Conflict')),
        throwsStateError,
      );
      expect((await repo.fetchMessages('c')).first, first);
      expect(() => messages.clear(), throwsUnsupportedError);
    },
  );
}
