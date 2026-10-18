import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/timing_rule.dart';

class RulesSection extends StatelessWidget {
  const RulesSection({super.key, required this.rules});
  final List<TimingRule> rules;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(title: 'Timing rules'),
      const Text(
        'Limits apply to each side. Direct and cross totals are shared across all witnesses.',
      ),
      const SizedBox(height: Spacing.md),
      for (final rule in rules)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: GavelCard(
            key: GavelKeys.caseRecord(rule.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.phase.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${rule.minutes} min${rule.sharedAcrossWitnesses ? ' total' : ''} per side',
                ),
              ],
            ),
          ),
        ),
      if (rules.isEmpty)
        const EmptyState(
          icon: Icons.timer_outlined,
          title: 'No timing rules yet',
        ),
    ],
  );
}
