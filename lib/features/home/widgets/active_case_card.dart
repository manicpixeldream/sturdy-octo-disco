import 'package:material_ui/material_ui.dart';

import '../../../core/dates.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/case_file.dart';

class ActiveCaseCard extends StatelessWidget {
  const ActiveCaseCard({
    super.key,
    required this.caseFile,
    required this.daysUntilTrial,
    required this.readiness,
  });

  final CaseFile caseFile;
  final int daysUntilTrial;
  final double readiness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (readiness * 100).round();
    return GavelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('ACTIVE CASE', style: theme.textTheme.labelSmall),
              ),
              StatusPill(
                status: percent >= 80
                    ? GavelStatus.ready
                    : GavelStatus.inProgress,
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(caseFile.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.xs),
          Text(
            trialCountdownLabel(daysUntilTrial),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          ProgressBar(value: readiness),
          const SizedBox(height: Spacing.xs),
          Text('$percent% team readiness', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
