import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/load_failure.dart';
import '../../data/models/chat_message.dart';
import '../../state/chat_controller.dart';
import '../../state/case_controller.dart';
import '../../state/team_controller.dart';
import '../../state/task_controller.dart';
import '../../state/role_controller.dart';
import '../../state/session_controller.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_tile.dart';

class TeamChatPage extends StatefulWidget {
  const TeamChatPage({super.key});
  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage> {
  final _scroll = ScrollController();
  String? _lastMessage;
  String? _caseId;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final cases = context.watch<CaseController>();
    final team = context.watch<TeamController>();
    final tasks = context.watch<TaskController>();
    final session = context.watch<SessionController>();
    final roles = session.sharedWorkspace
        ? null
        : context.watch<RoleController>();
    if (_caseId != chat.caseId) {
      _caseId = chat.caseId;
      _lastMessage = null;
    }
    final last = chat.messages.lastOrNull?.id;
    if (last != null && last != _lastMessage) {
      final initial = _lastMessage == null;
      final nearBottom =
          !_scroll.hasClients || _scroll.position.extentAfter < 120;
      _lastMessage = last;
      if (initial ||
          nearBottom ||
          chat.messages.last.senderId == session.currentTeammateId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    }
    final failed =
        cases.loadFailed ||
        team.loadFailed ||
        tasks.loadFailed ||
        roles?.loadFailed == true ||
        chat.loadFailed;
    final loaded =
        cases.isLoaded &&
        team.isLoaded &&
        tasks.isLoaded &&
        roles?.isLoaded != false &&
        chat.isLoaded;
    return WorkspacePage(
      title: 'Team chat',
      leading: IconButton(
        key: const ValueKey('chat_back'),
        tooltip: 'Back to Team',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(Routes.team),
      ),
      child: failed
          ? SingleChildScrollView(
              child: LoadFailure(
                title: 'Team chat unavailable',
                onRetry: () {
                  if (cases.loadFailed) cases.load();
                  if (team.loadFailed) team.load();
                  if (tasks.loadFailed) tasks.load();
                  if (roles?.loadFailed == true) roles?.load();
                  if (chat.loadFailed) chat.load();
                },
              ),
            )
          : !loaded
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 500 ||
                    (constraints.maxWidth < 360 && constraints.maxHeight < 700);
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            Spacing.xl,
                            compact ? Spacing.xs : Spacing.lg,
                            Spacing.xl,
                            Spacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!compact) ...[
                                Text(
                                  'One team. One conversation.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall,
                                ),
                                const SizedBox(height: Spacing.sm),
                              ],
                              Text(
                                session.sharedWorkspace
                                    ? 'Shared with your team'
                                    : !session.persistsLocalWork
                                    ? 'Local demo · This session'
                                    : compact
                                    ? 'Local demo · Saved in this browser'
                                    : '${cases.activeCase!.title} · Local demo channel. No messages or notifications are sent to teammates.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: chat.messages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(Spacing.xl),
                                child: Text(
                                  session.sharedWorkspace
                                      ? 'Start the conversation. You can link a task or exhibit.'
                                      : 'Start the conversation. Link a task, exhibit, or draft to give your message context.',
                                  key: const ValueKey('chat_empty'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : ListView(
                              controller: _scroll,
                              key: const ValueKey('chat_messages'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.xl,
                                vertical: Spacing.md,
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 840,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (final message in chat.messages)
                                          ChatMessageTile(
                                            key: ValueKey(
                                              'chat_message_${message.id}',
                                            ),
                                            message: message,
                                            senderName:
                                                team
                                                    .byId(message.senderId)
                                                    ?.name ??
                                                'Former teammate',
                                            isMine:
                                                message.senderId ==
                                                session.currentTeammateId,
                                            mentionAvailable:
                                                chat.mentionAvailable,
                                            onMention: (mention) => context
                                                .push(switch (mention.kind) {
                                                  ChatMentionKind.task =>
                                                    Routes.teamTask(
                                                      mention.itemId,
                                                    ),
                                                  ChatMentionKind.exhibit =>
                                                    Routes.researchSource(
                                                      mention.itemId,
                                                    ),
                                                  ChatMentionKind.draft =>
                                                    mention.itemId,
                                                }),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (session.sharedWorkspace &&
                        team.isLoaded &&
                        team.byId(session.currentTeammateId) == null)
                      const Padding(
                        padding: EdgeInsets.all(Spacing.md),
                        child: Text(
                          'Ask your team lead to add you to the roster to post messages.',
                        ),
                      ),
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .65,
                      ),
                      child: SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 1,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 840),
                            child: ChatComposer(
                              key: ValueKey('chat_composer_${chat.caseId}'),
                              enabled:
                                  team.byId(session.currentTeammateId) != null,
                              sending: chat.isSending,
                              failed: chat.sendFailed,
                              items: chat.availableMentions,
                              onSend: chat.send,
                              initialText: chat.draftText,
                              initialMentions: chat.draftMentions,
                              onDraftChanged: chat.saveDraft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
