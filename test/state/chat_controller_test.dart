import 'package:gavel/data/models/task_item.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/storage/workspace_storage.dart';
import 'package:gavel/data/models/chat_message.dart';
import 'package:gavel/data/models/case_file.dart';
import 'package:gavel/data/mock/mock_chat_repository.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';

import '../helpers/chat_fixture.dart';

class FlakyChat extends MockChatRepository {
  bool fail = true, failLoad = false;
  Completer<void>? pending;
  final List<ChatMessage> attempts = [];
  @override
  Future<List<ChatMessage>> fetchMessages(String caseId) async {
    if (failLoad) throw StateError('offline');
    return super.fetchMessages(caseId);
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    attempts.add(message);
    await pending?.future;
    if (fail) throw StateError('offline');
    return super.sendMessage(message);
  }
}

class SwitchingCase extends MockCaseRepository {
  SwitchingCase(SeedData seed)
    : current = seed.caseFile,
      super(
        activeCase: seed.caseFile,
        exhibits: seed.exhibits,
        witnesses: seed.witnesses,
      );
  CaseFile current;
  @override
  Future<CaseFile> fetchActiveCase() async => current;
}

void main() {
  for (final (sent, edited) in [(true, false), (true, true), (false, false)]) {
    test(
      'restores interrupted chat send (sent: $sent, edited: $edited)',
      () async {
        final storage = WorkspaceStorage.memory();
        final pending = ChatMessage(
          id: 'interrupted',
          caseId: 'case_harmon',
          senderId: 'tm_sofia',
          text: 'Review the opening',
          createdAt: DateTime(2026, 10, 26, 10),
        );
        final draft = edited ? 'New draft' : pending.text;
        storage.write('chatDraft.${pending.caseId}', {
          'text': draft,
          'mentions': [],
          'pending': pending.toMap(),
        });
        if (sent) {
          await MockChatRepository(const [], storage).sendMessage(pending);
        }

        final fixture = await ChatFixture.create(storage: storage);
        addTearDown(fixture.dispose);
        expect(fixture.chat.draftText, sent && !edited ? '' : draft);
        expect(fixture.chat.sendFailed, !sent);
        if (!sent) {
          expect(await fixture.chat.send(draft, []), isTrue);
        }
        expect(fixture.chat.messages.single, pending);
      },
    );
  }

  test('send appends current author, canonical links and timestamp; reload does not duplicate', () async {
    final f = await ChatFixture.create();
    addTearDown(f.dispose);
    expect(
      await f.chat.send(' Review this ', [
        const ChatMention(
          kind: ChatMentionKind.exhibit,
          itemId: 'ex_1',
          label: 'Spoofed title',
        ),
      ]),
      isTrue,
    );
    final message = f.chat.messages.single;
    expect(message.senderId, 'tm_sofia');
    expect(message.text, 'Review this');
    expect(message.mentions.single.label, 'Ex. 1 · Fire scene diagram');
    await f.chat.load();
    expect(f.chat.messages.length, 1);
    expect(await f.chat.send('', []), isFalse);
    expect(
      await f.chat.send('Missing item', [
        const ChatMention(
          kind: ChatMentionKind.task,
          itemId: 'missing',
          label: 'Missing',
        ),
      ]),
      isFalse,
    );
    expect(f.chat.messages.length, 1);
  });
  test(
    'failed send preserves the request ID on retry and blocks concurrent sends',
    () async {
      final repo = FlakyChat();
      final f = await ChatFixture.create(repository: repo);
      addTearDown(f.dispose);
      expect(await f.chat.send('Keep draft', []), isFalse);
      expect(f.chat.messages, isEmpty);
      expect(f.chat.sendFailed, isTrue);
      repo.fail = false;
      repo.pending = Completer<void>();
      final retry = f.chat.send('Keep draft', []);
      expect(f.chat.isSending, isTrue);
      expect(await f.chat.send('Duplicate', []), isFalse);
      repo.pending!.complete();
      expect(await retry, isTrue);
      expect(repo.attempts[0], repo.attempts[1]);
      expect(f.chat.messages.length, 1);
      expect(f.chat.sendFailed, isFalse);
    },
  );
  test(
    'load failure retries and mention-only messages are supported',
    () async {
      final repo = FlakyChat()
        ..failLoad = true
        ..fail = false;
      final f = await ChatFixture.create(repository: repo);
      addTearDown(f.dispose);
      expect(f.chat.loadFailed, isTrue);
      repo.failLoad = false;
      await f.chat.load();
      expect(f.chat.isLoaded, isTrue);
      expect(await f.chat.send('', [f.chat.availableMentions.first]), isTrue);
      expect(f.chat.messages.single.text, isEmpty);
    },
  );
  test('disposed sends cannot append or notify', () async {
    final repo = FlakyChat()
      ..fail = false
      ..pending = Completer<void>();
    final f = await ChatFixture.create(repository: repo);
    final send = f.chat.send('Hello', []);
    f.chat.dispose();
    repo.pending!.complete();
    expect(await send, isFalse);
    expect(f.chat.messages, isEmpty);
    f.tasks.dispose();
    f.team.dispose();
    f.cases.dispose();
  });
  test('old case send completion cannot enter the new channel', () async {
    final seed = SeedData.harmon(today: DateTime(2026));
    final cases = SwitchingCase(seed);
    final repo = FlakyChat()
      ..fail = false
      ..pending = Completer<void>();
    final f = await ChatFixture.create(repository: repo, caseRepository: cases);
    addTearDown(f.dispose);
    final send = f.chat.send('Old channel', []);
    cases.current = seed.caseFile.copyWith(id: 'other_case');
    await f.cases.load();
    await f.chat.load();
    repo.pending!.complete();
    expect(await send, isFalse);
    expect(f.chat.caseId, 'other_case');
    expect(f.chat.messages, isEmpty);
    expect(f.chat.isSending, isFalse);
  });
  test(
    'send timeouts preserve retry state without adding an unsent message',
    () async {
      final repo = FlakyChat()
        ..fail = false
        ..pending = Completer<void>();
      final f = await ChatFixture.create(
        repository: repo,
        timeout: Duration.zero,
      );
      addTearDown(f.dispose);
      expect(await f.chat.send('Timeout', []), isFalse);
      expect(f.chat.sendFailed, isTrue);
      expect(f.chat.messages, isEmpty);
      expect(f.chat.isSending, isFalse);
      repo.pending!.complete();
    },
  );
  test(
    'new role responsibility tasks become available for mentions immediately',
    () async {
      final f = await ChatFixture.create();
      addTearDown(f.dispose);
      f.tasks.setRoleTasks([
        TaskItem(
          id: 'role_new',
          title: 'Rehearse closing',
          assigneeId: 'tm_sofia',
          dueDate: DateTime(2026, 11),
        ),
      ]);
      final mention = f.chat.availableMentions.singleWhere(
        (m) => m.itemId == 'role_new',
      );
      expect(
        await f.chat.send('Please review this responsibility', [mention]),
        isTrue,
      );
      expect(f.chat.messages.single.mentions.single.itemId, 'role_new');
    },
  );
}
