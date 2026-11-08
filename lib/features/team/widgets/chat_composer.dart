import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../data/models/chat_message.dart';
import 'chat_mention_picker.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.enabled,
    required this.sending,
    required this.failed,
    required this.items,
    required this.onSend,
  });
  final bool enabled, sending, failed;
  final List<ChatMention> items;
  final Future<bool> Function(String, List<ChatMention>) onSend;
  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _text = TextEditingController();
  List<ChatMention> _mentions = const [];
  bool _submitting = false;
  bool get _enabled => widget.enabled && !widget.sending && !_submitting;
  Future<void> _submit() async {
    if (!_enabled || (_text.text.trim().isEmpty && _mentions.isEmpty)) return;
    setState(() => _submitting = true);
    final sent = await widget.onSend(_text.text, _mentions);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (sent) {
        _text.clear();
        _mentions = const [];
      }
    });
  }

  Future<void> _pick() async {
    final picked = await showModalBottomSheet<List<ChatMention>>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          ChatMentionPicker(items: widget.items, initial: _mentions),
    );
    if (mounted && picked != null) {
      setState(() => _mentions = List.unmodifiable(picked));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.md,
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              _submit,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mentions.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final mention in _mentions)
                      Padding(
                        padding: const EdgeInsets.only(right: Spacing.sm),
                        child: Tooltip(
                          message: mention.label,
                          child: InputChip(
                            key: ValueKey('chat_draft_${mention.id}'),
                            label: SizedBox(
                              width: 170,
                              child: Text(
                                mention.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onDeleted: _enabled
                                ? () => setState(
                                    () => _mentions = _mentions
                                        .where((m) => m.id != mention.id)
                                        .toList(),
                                  )
                                : null,
                            deleteButtonTooltipMessage:
                                'Remove ${mention.label}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            TextField(
              key: const ValueKey('chat_input'),
              controller: _text,
              enabled: _enabled,
              minLines: 1,
              maxLines: 3,
              maxLength: 2000,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Message your team',
                hintText: 'Coordinate your preparation…',
                counterText: '',
              ),
            ),
            if (widget.failed)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(
                  'Could not send. Your draft is still here. Check linked items and try again.',
                  key: const ValueKey('chat_send_error'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: Spacing.sm),
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  if (constraints.maxWidth < 360)
                    IconButton(
                      key: const ValueKey('chat_link_item'),
                      tooltip: 'Link a task or exhibit',
                      onPressed: _enabled ? _pick : null,
                      icon: const Icon(Icons.link, size: 20),
                    )
                  else
                    TextButton.icon(
                      key: const ValueKey('chat_link_item'),
                      onPressed: _enabled ? _pick : null,
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(
                        'Link item${_mentions.isEmpty ? '' : ' (${_mentions.length})'}',
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('chat_send'),
                    onPressed:
                        _enabled &&
                            (_text.text.trim().isNotEmpty ||
                                _mentions.isNotEmpty)
                        ? _submit
                        : null,
                    child: Text(
                      widget.sending || _submitting ? 'Sending…' : 'Send',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
