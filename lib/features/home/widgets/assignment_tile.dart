import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/task_item.dart';
import '../../../data/models/exam_script.dart';

class AssignmentTile extends StatelessWidget {
  const AssignmentTile({
    super.key,
    required this.task,
    required this.dueLabel,
    required this.onOpen,
    this.script,
    this.reviewerName,
  });

  final TaskItem task;
  final String dueLabel;
  final VoidCallback onOpen;
  final ExamScript? script;
  final String? reviewerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GavelCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.xs),
                Text(
                  task.isDone ? 'Done' : dueLabel,
                  style: theme.textTheme.bodySmall,
                ),
                if (script case final draft?)
                  Text(
                    reviewerName == null
                        ? draft.status.label
                        : '${draft.status.label} · Reviewer: $reviewerName',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          StatusPill(
            status: task.isDone ? GavelStatus.ready : GavelStatus.inProgress,
            label: task.isDone ? 'Done' : 'Open',
          ),
          const SizedBox(width: Spacing.sm),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
