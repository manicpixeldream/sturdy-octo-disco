import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/data/mock/mock_chat_repository.dart';
import 'package:gavel/data/models/chat_message.dart';
import 'package:gavel/features/team/team_chat_page.dart';
import 'package:gavel/state/chat_controller.dart';
import 'package:gavel/state/theme_controller.dart';

import '../../helpers/pump_app.dart';

class FlakyPageChat extends MockChatRepository {
  bool fail = true, failLoad = false;
  @override
  Future<List<ChatMessage>> fetchMessages(String caseId) async {
    if (failLoad) throw StateError('offline');
    return super.fetchMessages(caseId);
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    if (fail) throw StateError('offline');
    return super.sendMessage(message);
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
    final scrollable = find
        .ancestor(
          of: target,
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    await tester.drag(scrollable, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> click(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  final clock = Clock.fixed(DateTime(2026, 10, 26, 10));
  testWidgets('sends Unicode within the visible character limit', (
    tester,
  ) async {
    await pumpGavelApp(tester, initialLocation: Routes.teamChat, clock: clock);
    final message = '🙂' * 1100;
    final input = find.byKey(const ValueKey('chat_input'));
    await tester.enterText(input, message);
    await click(tester, 'chat_send');
    final chat = tester
        .element(find.byType(TeamChatPage))
        .read<ChatController>();
    expect(chat.messages.single.text, message);
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
  });

  testWidgets(
    'Team entry opens chat; send appends a message and clears only on success',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: Routes.team, clock: clock);
      await click(tester, 'team_open_chat');
      expect(find.byType(TeamChatPage), findsOneWidget);
      expect(find.byKey(const ValueKey('chat_empty')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('chat_send')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat_input')),
        'Ready to rehearse.',
      );
      await click(tester, 'chat_send');
      expect(find.text('Ready to rehearse.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat_input')))
            .controller!
            .text,
        isEmpty,
      );
      final chat = tester
          .element(find.byType(TeamChatPage))
          .read<ChatController>();
      expect(chat.messages.length, 1);
    },
  );
  testWidgets('task and exhibit references open their actual linked items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpGavelApp(tester, initialLocation: Routes.teamChat, clock: clock);
    await tester.enterText(
      find.byKey(const ValueKey('chat_input')),
      'Please review these.',
    );
    await click(tester, 'chat_link_item');
    await tester.enterText(
      find.byKey(const ValueKey('chat_mention_search')),
      'Theo',
    );
    await tester.pumpAndSettle();
    await click(tester, 'mention_pick_task:task_5');
    await click(tester, 'chat_mention_clear');
    await click(tester, 'mention_kind_exhibit');
    await click(tester, 'mention_pick_exhibit:ex_1');
    await click(tester, 'chat_mentions_apply');
    await click(tester, 'chat_send');
    final chat = tester
        .element(find.byType(TeamChatPage))
        .read<ChatController>();
    final id = chat.messages.single.id;
    await click(tester, 'chat_mention_${id}_task:task_5');
    expect(find.text('Draft cross of Theo Lindqvist'), findsOneWidget);
    expect(find.text('Assigned to Marcus Bell'), findsOneWidget);
    await click(tester, 'task_detail_back');
    await click(tester, 'chat_mention_${id}_exhibit:ex_1');
    expect(
      GoRouter.of(tester.element(find.text('Source'))).state.uri.path,
      '/research/source/ex_1',
    );
    expect(find.text('Fire scene diagram'), findsOneWidget);
  });
  testWidgets(
    'failed send preserves draft and links; retry produces one message',
    (tester) async {
      final repo = FlakyPageChat();
      await pumpGavelApp(
        tester,
        initialLocation: Routes.teamChat,
        clock: clock,
        chatRepository: repo,
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat_input')),
        'Keep my draft',
      );
      await click(tester, 'chat_link_item');
      await click(tester, 'mention_pick_task:task_1');
      await click(tester, 'chat_mentions_apply');
      await click(tester, 'chat_send');
      expect(find.byKey(const ValueKey('chat_send_error')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat_input')))
            .controller!
            .text,
        'Keep my draft',
      );
      expect(await repo.fetchMessages('case_harmon'), isEmpty);
      expect(
        find.byKey(const ValueKey('chat_draft_task:task_1')),
        findsOneWidget,
      );
      repo.fail = false;
      await click(tester, 'chat_send');
      expect((await repo.fetchMessages('case_harmon')).length, 1);
      expect(find.text('Keep my draft'), findsOneWidget);
    },
  );
  testWidgets('load failure retries to an honest empty channel', (
    tester,
  ) async {
    final repo = FlakyPageChat()..failLoad = true;
    await pumpGavelApp(
      tester,
      initialLocation: Routes.teamChat,
      clock: clock,
      chatRepository: repo,
    );
    expect(find.text('Team chat unavailable'), findsOneWidget);
    repo.failLoad = false;
    await click(tester, 'load_retry');
    expect(find.byKey(const ValueKey('chat_empty')), findsOneWidget);
  });
  testWidgets(
    'link picker searches and limits selections to five; links can be removed',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpGavelApp(
        tester,
        initialLocation: Routes.teamChat,
        clock: clock,
      );
      await click(tester, 'chat_link_item');
      for (var i = 1; i <= 5; i++) {
        await click(tester, 'mention_pick_task:task_$i');
      }
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('mention_pick_task:task_6')),
            )
            .onChanged,
        isNull,
      );
      await click(tester, 'chat_mentions_apply');
      expect(
        find.byKey(const ValueKey('chat_draft_task:task_1')),
        findsOneWidget,
      );
      final remove = find.byTooltip(
        'Remove Draft direct exam of Officer Reyes',
      );
      await reveal(tester, remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat_draft_task:task_1')),
        findsNothing,
      );
      await click(tester, 'chat_send');
      final chat = tester
          .element(find.byType(TeamChatPage))
          .read<ChatController>();
      expect(chat.messages.single.mentions.length, 4);
      expect(chat.messages.single.text, isEmpty);
    },
  );
  testWidgets('Ctrl+Enter sends without needing the mouse', (tester) async {
    await pumpGavelApp(tester, initialLocation: Routes.teamChat, clock: clock);
    await tester.enterText(
      find.byKey(const ValueKey('chat_input')),
      'Keyboard message',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Keyboard message'), findsOneWidget);
  });
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets('chat, references and keyboard fit $width across themes', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final message = ChatMessage(
        id: 'seed',
        caseId: 'case_harmon',
        senderId: 'tm_marcus',
        text: 'Review the witness preparation plan and the evidence.',
        createdAt: clock.now(),
        mentions: [
          const ChatMention(
            kind: ChatMentionKind.task,
            itemId: 'task_1',
            label: 'Draft direct exam of Officer Reyes',
          ),
        ],
      );
      await pumpGavelApp(
        tester,
        initialLocation: Routes.teamChat,
        clock: clock,
        chatRepository: MockChatRepository([message]),
      );
      final theme = tester
          .element(find.byType(TeamChatPage))
          .read<ThemeController>();
      for (final variant in GavelThemeVariant.values) {
        theme.select(variant);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat_input')),
        'Keyboard stays usable.',
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('chat_send')));
      expect(
        tester.getBottomRight(find.byKey(const ValueKey('chat_send'))).dy,
        lessThanOrEqualTo(700),
      );
      expect(tester.takeException(), isNull);
      await click(tester, 'chat_link_item');
      expect(tester.takeException(), isNull);
      await click(tester, 'chat_mentions_cancel');
      expect(tester.takeException(), isNull);
    });
  }
}
