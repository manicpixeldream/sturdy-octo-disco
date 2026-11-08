import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../data/models/chat_message.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    super.key,
    required this.message,
    required this.senderName,
    required this.isMine,
    required this.onMention,
    required this.mentionAvailable,
  });
  final ChatMessage message;
  final String senderName;
  final bool isMine;
  final ValueChanged<ChatMention> onMention;
  final bool Function(ChatMention) mentionAvailable;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InitialsAvatar(name: senderName, size: 32),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMine ? '$senderName · You' : senderName,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a')
                              .format(message.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                SelectableText(
                  message.text,
                  key: ValueKey('chat_body_${message.id}'),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
              for (final mention in message.mentions)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: OutlinedButton(
                    key: ValueKey('chat_mention_${message.id}_${mention.id}'),
                    onPressed: () => onMention(mention),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            mention.kind == ChatMentionKind.task
                                ? Icons.checklist
                                : Icons.description_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              '${mention.kind.label} · ${mention.label}${mentionAvailable(mention) ? '' : ' (unavailable)'}',
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
