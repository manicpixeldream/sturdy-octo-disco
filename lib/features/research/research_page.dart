import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/gavel_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../state/case_controller.dart';
import '../../state/research_controller.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/library_list.dart';
import 'widgets/research_input_bar.dart';
import 'widgets/suggestion_chips.dart';

class ResearchPage extends StatefulWidget {
  const ResearchPage({super.key, this.messageId});
  final String? messageId;
  @override
  State<ResearchPage> createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> {
  bool _library = false;
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  String? _focusedMessage;
  int _messageCount = 0;

  @override
  void didUpdateWidget(ResearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messageId != null || widget.messageId != oldWidget.messageId) {
      _focusedMessage = null;
      if (widget.messageId != null) _library = false;
    }
  }

  void _openSource(String id) => context.push(Routes.researchSource(id));
  void _send(String question) =>
      unawaited(context.read<ResearchController>().send(question));

  void _syncScroll(ResearchController controller) {
    final target = widget.messageId;
    if (target != null &&
        _focusedMessage != target &&
        controller.messages.any((m) => m.id == target)) {
      _focusedMessage = target;
      _library = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _messageKeys[target]?.currentContext;
        if (mounted && context != null) {
          Scrollable.ensureVisible(context, alignment: 0.1);
        }
      });
    } else if (controller.messages.length != _messageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
    _messageCount = controller.messages.length;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ResearchController>();
    final cases = context.watch<CaseController>();
    _syncScroll(controller);
    for (final message in controller.messages) {
      _messageKeys.putIfAbsent(message.id, () => GlobalKey());
    }
    final appTheme = Theme.of(context);
    final theme = appTheme.brightness == Brightness.light
        ? GavelTheme.dark()
        : appTheme;
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => WorkspacePage(
          title: 'AI research',
          child: cases.loadFailed
              ? Center(
                  child: LoadFailure(
                    title: 'Could not load the case',
                    onRetry: cases.load,
                  ),
                )
              : controller.loadFailed
              ? Center(
                  child: LoadFailure(
                    title: 'Could not load research sources',
                    onRetry: controller.load,
                  ),
                )
              : !controller.isLoaded
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 500;
                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 928),
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
                                      'Research with context.',
                                      style: theme.textTheme.displaySmall,
                                    ),
                                    const SizedBox(height: Spacing.sm),
                                  ],
                                  Text(
                                    '${cases.activeCase?.title ?? 'Case workspace'} · Demo researcher',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: Spacing.xs),
                                    Text(
                                      'Prepared answers with traceable sources. No live AI or web search.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: Spacing.sm),
                                  Row(
                                    children: [
                                      Semantics(
                                        selected: !_library,
                                        child: TextButton(
                                          key: const ValueKey(
                                            'research_ask_mode',
                                          ),
                                          onPressed: () =>
                                              setState(() => _library = false),
                                          child: Text(
                                            'Ask',
                                            style: TextStyle(
                                              fontWeight: !_library
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Semantics(
                                        selected: _library,
                                        child: TextButton(
                                          key: const ValueKey(
                                            'research_library_mode',
                                          ),
                                          onPressed: () =>
                                              setState(() => _library = true),
                                          child: Text(
                                            'Library (${controller.savedSources.length})',
                                            style: TextStyle(
                                              fontWeight: _library
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _library ? 1 : 0,
                            children: [
                              ListView(
                                key: const PageStorageKey(
                                  'research_chat_scroll',
                                ),
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(
                                  Spacing.xl,
                                  Spacing.lg,
                                  Spacing.xl,
                                  Spacing.xxl,
                                ),
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 880,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (widget.messageId != null &&
                                              !controller.messages.any(
                                                (m) => m.id == widget.messageId,
                                              ))
                                            const Text(
                                              'This answer is no longer in this session. Ask a new question below.',
                                            ),
                                          if (controller.messages.isEmpty) ...[
                                            Text(
                                              'Follow a fact. Test an inference.',
                                              style:
                                                  theme.textTheme.headlineSmall,
                                            ),
                                            const SizedBox(height: Spacing.md),
                                            Text(
                                              'Start with the packet, then open the supporting sources.',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            const SizedBox(height: Spacing.xl),
                                            SuggestionChips(
                                              onAsk: _send,
                                              enabled: !controller.isSending,
                                            ),
                                          ],
                                          for (final message
                                              in controller.messages)
                                            KeyedSubtree(
                                              key: _messageKeys[message.id],
                                              child: ChatBubble(
                                                key: ValueKey(
                                                  'research_${message.id}',
                                                ),
                                                message: message,
                                                sourceById:
                                                    controller.sourceById,
                                                onOpenSource: _openSource,
                                                highlighted:
                                                    widget.messageId ==
                                                    message.id,
                                              ),
                                            ),
                                          if (controller.isSending)
                                            const Padding(
                                              key: ValueKey(
                                                'research_reply_loading',
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: Spacing.lg,
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                  SizedBox(width: Spacing.md),
                                                  Expanded(
                                                    child: Text(
                                                      'Preparing a sourced response…',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (controller.replyFailed)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'The response could not be loaded. Your question is still here.',
                                                  key: ValueKey(
                                                    'research_reply_error',
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: Spacing.sm,
                                                ),
                                                Wrap(
                                                  spacing: Spacing.sm,
                                                  children: [
                                                    OutlinedButton(
                                                      key: const ValueKey(
                                                        'research_retry_reply',
                                                      ),
                                                      onPressed:
                                                          controller.retryReply,
                                                      child: const Text(
                                                        'Retry response',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      key: const ValueKey(
                                                        'research_dismiss_error',
                                                      ),
                                                      onPressed: controller
                                                          .dismissFailedReply,
                                                      child: const Text(
                                                        'Ask another question',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              WorkspaceScrollView(
                                storageKey: const PageStorageKey(
                                  'research_library_scroll',
                                ),
                                maxWidth: 880,
                                children: [
                                  LibraryList(
                                    controller: controller,
                                    onOpen: _openSource,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!_library)
                          ResearchInputBar(
                            enabled:
                                !controller.isSending &&
                                !controller.replyFailed,
                            onSend: _send,
                          ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
