import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/chat_message.dart';

void main() {
  const mention = ChatMention(
    kind: ChatMentionKind.task,
    itemId: 't',
    label: 'Prepare',
  );
  test(
    'messages and mentions roundtrip, trim text and own immutable collections',
    () {
      final mentions = [mention];
      final message = ChatMessage(
        id: 'm',
        caseId: 'c',
        senderId: 'a',
        text: ' Hello ',
        createdAt: DateTime(2026),
        mentions: mentions,
      );
      mentions.clear();
      expect(message.text, 'Hello');
      expect(message.mentions, [mention]);
      expect(
        ChatMessage.fromMap(
          Map<String, Object?>.from(
            jsonDecode(jsonEncode(message.toMap())) as Map,
          ),
        ),
        message,
      );
      expect(message.copyWith(text: 'Changed').text, 'Changed');
      expect(() => message.mentions.clear(), throwsUnsupportedError);
    },
  );
  test('blank, oversized, duplicated and invalid references are rejected', () {
    ChatMessage make(String text, List<ChatMention> mentions) => ChatMessage(
      id: 'm',
      caseId: 'c',
      senderId: 'a',
      text: text,
      createdAt: DateTime(2026),
      mentions: mentions,
    );
    expect(() => make(' ', []), throwsArgumentError);
    expect(() => make('a' * 2001, []), throwsArgumentError);
    expect(() => make('Hello', [mention, mention]), throwsArgumentError);
    expect(
      () => make('Hello', [
        const ChatMention(kind: ChatMentionKind.task, itemId: '', label: ''),
      ]),
      throwsArgumentError,
    );
    expect(make('', [mention]).mentions, [mention]);
  });
}
