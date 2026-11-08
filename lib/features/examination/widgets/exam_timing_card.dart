import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/timing_rule.dart';

class ExamTimingCard extends StatelessWidget {
  const ExamTimingCard({
    super.key,
    required this.scriptSeconds,
    required this.totalSeconds,
    required this.rule,
    required this.side,
  });
  final int scriptSeconds, totalSeconds;
  final TimingRule? rule;
  final String side;
  static String duration(int seconds) => '${seconds ~/ 60}m ${seconds % 60}s';
  @override
  Widget build(BuildContext context) {
    final limit = rule == null ? null : rule!.minutes * 60;
    return GavelCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing estimate',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.md),
          Text('This script: ${duration(scriptSeconds)}'),
          if (limit == null)
            const Text('No timing rule is available for this examination.')
          else ...[
            Text(
              '$side: ${duration(totalSeconds)} / ${rule!.minutes}m',
              key: const ValueKey('exam_shared_time'),
            ),
            const SizedBox(height: Spacing.md),
            ProgressBar(value: totalSeconds / limit),
            if (totalSeconds > limit)
              const StatusPill(
                key: ValueKey('exam_over_budget'),
                status: GavelStatus.flagged,
                label: 'Over time budget',
              ),
            const SizedBox(height: Spacing.sm),
            Text(
              rule!.sharedAcrossWitnesses
                  ? 'Shared across all $side ${rule!.phase == TrialPhase.direct ? 'direct' : 'cross'} scripts. This is not a separate allowance per witness.'
                  : 'The packet defines this allowance per examination.',
            ),
          ],
          const SizedBox(height: Spacing.sm),
          const Text(
            'Estimates include questions and expected answers. Rehearse with a timer; pauses and objections can add time.',
          ),
        ],
      ),
    );
  }
}
