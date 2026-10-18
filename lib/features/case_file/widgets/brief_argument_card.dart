import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../data/models/case_brief.dart';

class BriefArgumentCard extends StatelessWidget {
  const BriefArgumentCard({super.key, required this.argument});
  final BriefArgument argument;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${argument.side.label} may argue', style: text.titleMedium),
          const SizedBox(height: Spacing.sm),
          Text(argument.argument),
          const SizedBox(height: Spacing.lg),
          Text('Suggested counter', style: text.labelMedium),
          const SizedBox(height: Spacing.xs),
          Text(argument.counter, style: text.bodySmall),
        ],
      ),
    );
  }
}
