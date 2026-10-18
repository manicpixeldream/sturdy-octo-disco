import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../data/models/research_message.dart';
import '../../../data/models/research_source.dart';
import 'citation_chip.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.sourceById,
    required this.onOpenSource,
    this.highlighted = false,
  });
  final ResearchMessage message;
  final ResearchSource? Function(String) sourceById;
  final ValueChanged<String> onOpenSource;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.role == ResearchRole.user) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.xl),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('YOU', style: theme.textTheme.labelSmall),
                    const SizedBox(height: Spacing.xs),
                    SelectableText(message.text),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final sourceNumbers = <String, int>{};
    for (final id in message.points.expand((p) => p.sourceIds)) {
      sourceNumbers.putIfAbsent(id, () => sourceNumbers.length + 1);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: highlighted
            ? Border(
                left: BorderSide(color: theme.colorScheme.secondary, width: 2),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          highlighted ? Spacing.lg : 0,
          Spacing.sm,
          0,
          Spacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GAVEL · PREPARED RESPONSE',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Semantics(
              header: true,
              child: Text(message.text, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: Spacing.xl),
            for (final (index, point) in message.points.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${index + 1}.',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            point.text,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: Spacing.sm),
                          Wrap(
                            spacing: Spacing.xs,
                            runSpacing: Spacing.xs,
                            children: [
                              for (final id in point.sourceIds)
                                if (sourceById(id) case final source?)
                                  CitationChip(
                                    key: ValueKey(
                                      'citation_${message.id}_${index}_$id',
                                    ),
                                    source: source,
                                    number: sourceNumbers[id]!,
                                    onOpen: () => onOpenSource(id),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
