import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_segmented_control.dart';
import '../../../data/models/chat_message.dart';

class ChatMentionPicker extends StatefulWidget {
  const ChatMentionPicker({
    super.key,
    required this.items,
    required this.initial,
  });
  final List<ChatMention> items, initial;
  @override
  State<ChatMentionPicker> createState() => _ChatMentionPickerState();
}

class _ChatMentionPickerState extends State<ChatMentionPicker> {
  final _search = TextEditingController();
  late final Map<String, ChatMention> _selected = {
    for (final m in widget.initial) m.id: m,
  };
  ChatMentionKind _kind = ChatMentionKind.task;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final items = widget.items
        .where((m) => m.kind == _kind && m.label.toLowerCase().contains(query))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link a task, exhibit, or draft',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.sm),
                Text('${_selected.length}/5 references selected'),
                const SizedBox(height: Spacing.md),
                GavelSegmentedControl<ChatMentionKind>(
                  selected: _kind,
                  options: {
                    for (final kind in ChatMentionKind.values)
                      kind: kind.plural,
                  },
                  keyFor: (kind) => ValueKey('mention_kind_${kind.name}'),
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  key: const ValueKey('chat_mention_search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Search ${_kind.plural.toLowerCase()}',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('chat_mention_clear'),
                            tooltip: 'Clear search',
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No matching items.'))
                      : ListView(
                          children: [
                            for (final mention in items)
                              CheckboxListTile(
                                key: ValueKey('mention_pick_${mention.id}'),
                                title: Text(mention.label),
                                value: _selected.containsKey(mention.id),
                                onChanged:
                                    _selected.length >= 5 &&
                                        !_selected.containsKey(mention.id)
                                    ? null
                                    : (value) => setState(() {
                                        if (value!) {
                                          _selected[mention.id] = mention;
                                        } else {
                                          _selected.remove(mention.id);
                                        }
                                      }),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.md,
                  children: [
                    TextButton(
                      key: const ValueKey('chat_mentions_cancel'),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      key: const ValueKey('chat_mentions_apply'),
                      onPressed: () =>
                          Navigator.pop(context, _selected.values.toList()),
                      child: const Text('Apply links'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
