import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/stipulation.dart';

class StipulationsSection extends StatelessWidget {
  const StipulationsSection({super.key, required this.stipulations});
  final List<Stipulation> stipulations;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: 'Stipulations (${stipulations.length})'),
      for (final stipulation in stipulations)
        Padding(
          key: GavelKeys.caseRecord(stipulation.id),
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  '${stipulation.number}'.padLeft(2, '0'),
                  semanticsLabel: 'Stipulation ${stipulation.number}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  stipulation.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      if (stipulations.isEmpty)
        const EmptyState(
          icon: Icons.fact_check_outlined,
          title: 'No stipulations yet',
        ),
    ],
  );
}
