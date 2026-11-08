import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/exam_question.dart';
import '../../../data/models/exhibit.dart';

class QuestionTile extends StatelessWidget {
  const QuestionTile({
    super.key,
    required this.question,
    required this.number,
    required this.exhibitById,
    required this.onEdit,
    required this.onDelete,
    required this.onUp,
    required this.onDown,
    required this.onExhibit,
    this.highlighted = false,
  });
  final ExamQuestion question;
  final int number;
  final Exhibit? Function(String) exhibitById;
  final VoidCallback? onEdit, onDelete, onUp, onDown;
  final ValueChanged<String> onExhibit;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: highlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('QUESTION $number', style: theme.textTheme.labelSmall),
                  Text(
                    '${question.estimatedSeconds}s estimated',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (question.flagged)
                    const StatusPill(
                      status: GavelStatus.flagged,
                      label: 'Review',
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(question.text, style: theme.textTheme.bodyLarge),
              if (question.exhibitIds.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final id in question.exhibitIds)
                      TagChip(
                        key: ValueKey('exam_link_${question.id}_$id'),
                        label: exhibitById(id)?.label ?? id,
                        onTap: () => onExhibit(id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.md),
              Wrap(
                spacing: Spacing.sm,
                children: [
                  TextButton(
                    key: ValueKey('question_edit_${question.id}'),
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  IconButton(
                    key: ValueKey('question_up_${question.id}'),
                    tooltip: 'Move question up',
                    onPressed: onUp,
                    icon: const Icon(Icons.arrow_upward, size: 18),
                  ),
                  IconButton(
                    key: ValueKey('question_down_${question.id}'),
                    tooltip: 'Move question down',
                    onPressed: onDown,
                    icon: const Icon(Icons.arrow_downward, size: 18),
                  ),
                  TextButton(
                    key: ValueKey('question_delete_${question.id}'),
                    onPressed: onDelete,
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
