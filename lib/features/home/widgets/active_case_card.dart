import 'package:material_ui/material_ui.dart';

import '../../../core/dates.dart';
import '../../../core/theme/spacing.dart';
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
    final text = Theme.of(context).textTheme;
    final percent = (readiness * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR ACTIVE CASE', style: text.labelSmall),
        const SizedBox(height: Spacing.md),
        Semantics(
          header: true,
          child: Text(caseFile.title, style: text.displayMedium),
        ),
        const SizedBox(height: Spacing.sm),
        Text(trialCountdownLabel(daysUntilTrial), style: text.bodySmall),
        const SizedBox(height: Spacing.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$percent% team readiness',
                      style: text.labelMedium,
                    ),
                  ),
                  StatusPill(
                    status: percent >= 80
                        ? GavelStatus.ready
                        : GavelStatus.inProgress,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              ProgressBar(value: readiness, height: 3),
            ],
          ),
        ),
      ],
    );
  }
}
