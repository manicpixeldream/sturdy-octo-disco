import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/theme/spacing.dart';

class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({
    super.key,
    required this.minutes,
    required this.target,
    required this.progress,
  });
  final int minutes, target;
  final double progress;
  @override
  Widget build(BuildContext context) => GavelCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly practice goal',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Spacing.md),
        Text(
          '$minutes / $target minutes planned',
          key: const ValueKey('weekly_goal_minutes'),
        ),
        const SizedBox(height: Spacing.md),
        ProgressBar(value: progress),
        const SizedBox(height: Spacing.sm),
        const Text(
          'Counts your scheduled sessions for the entire selected week, including earlier sessions. This measures planned practice, not attendance.',
        ),
      ],
    ),
  );
}
