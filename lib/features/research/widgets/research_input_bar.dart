import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';

class ResearchInputBar extends StatefulWidget {
  const ResearchInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
  });
  final bool enabled;
  final ValueChanged<String> onSend;
  @override
  State<ResearchInputBar> createState() => _ResearchInputBarState();
}

class _ResearchInputBarState extends State<ResearchInputBar> {
  final _text = TextEditingController();
  void _submit() {
    final value = _text.text.trim();
    if (!widget.enabled || value.isEmpty) return;
    widget.onSend(value);
    _text.clear();
    setState(() {});
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 928),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.md,
              ),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    control: true,
                  ): _submit,
                  const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                      _submit,
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('research_input'),
                        controller: _text,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 2000,
                        textInputAction: TextInputAction.send,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Ask about the case',
                          hintText: 'A question about facts or evidence…',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    IconButton.filled(
                      key: const ValueKey('research_send'),
                      tooltip: 'Send question',
                      onPressed: widget.enabled && _text.text.trim().isNotEmpty
                          ? _submit
                          : null,
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
