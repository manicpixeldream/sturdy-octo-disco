import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/trial_countdown.dart';
import '../../../core/theme/spacing.dart';
import '../../../data/models/case_file.dart';

/// Editorial header, retained at its existing API for the Case workspace.
class CaseHeaderCard extends StatelessWidget {
  const CaseHeaderCard({
    super.key,
    required this.caseFile,
    required this.daysUntilTrial,
    required this.exhibitCount,
    required this.witnessCount,
    required this.affidavitCount,
  });

  final CaseFile caseFile;
  final int daysUntilTrial;
  final int exhibitCount;
  final int witnessCount;
  final int affidavitCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final wide = constraints.maxWidth >= 700;
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CASE WORKSPACE', style: theme.textTheme.labelSmall),
          const SizedBox(height: Spacing.md),
          Semantics(
            header: true,
            child: Text(
              caseFile.title,
              style: wide
                  ? theme.textTheme.displayLarge
                  : theme.textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: Spacing.md),
          TrialCountdown(days: daysUntilTrial),
          const SizedBox(height: Spacing.sm),
          Text(
            DateFormat.yMMMd().format(caseFile.trialDate),
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
      final stats = Wrap(
        spacing: Spacing.xl,
        runSpacing: Spacing.sm,
        children: [
          for (final (count, label) in [
            (exhibitCount, 'exhibits'),
            (witnessCount, 'witnesses'),
            (affidavitCount, 'affidavits'),
          ])
            Text.rich(
              key: ValueKey('case_count_$label'),
              TextSpan(
                children: [
                  TextSpan(text: '$count', style: theme.textTheme.titleMedium),
                  TextSpan(text: ' $label', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xxl),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: Spacing.xl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: stats,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: Spacing.xl),
                  stats,
                ],
              ),
      );
    },
  );
}
