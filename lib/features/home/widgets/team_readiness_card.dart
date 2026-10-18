import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/teammate.dart';

class TeamReadinessCard extends StatelessWidget {
  const TeamReadinessCard({
    super.key,
    required this.readiness,
    required this.doneCount,
    required this.taskCount,
    required this.teammates,
    required this.readinessFor,
  });

  final double readiness;
  final int doneCount;
  final int taskCount;
  final List<Teammate> teammates;
  final double Function(String teammateId) readinessFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (readiness * 100).round();
    return GavelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team readiness', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.xs),
          Text(
            '$doneCount of $taskCount tasks done · $percent%',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          ProgressBar(value: readiness),
          const SizedBox(height: Spacing.lg),
          for (final teammate in teammates) ...[
            if (teammate != teammates.first) const SizedBox(height: Spacing.md),
            _TeammateReadinessRow(
              teammate: teammate,
              readiness: readinessFor(teammate.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeammateReadinessRow extends StatelessWidget {
  const _TeammateReadinessRow({
    required this.teammate,
    required this.readiness,
  });

  final Teammate teammate;
  final double readiness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        InitialsAvatar(name: teammate.name, size: 32),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teammate.name, style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.xs),
              ProgressBar(value: readiness, height: 6),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        Text(
          '${(readiness * 100).round()}%',
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }
}
