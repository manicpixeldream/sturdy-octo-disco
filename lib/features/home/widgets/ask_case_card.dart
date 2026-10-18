import 'package:material_ui/material_ui.dart';

import '../../../core/theme/gavel_theme.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';

class AskCaseCard extends StatelessWidget {
  const AskCaseCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = GavelTheme.accent(theme);
    return GavelCard(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(Spacing.xl),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: accent),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask the case', style: theme.textTheme.titleMedium),
                Text(
                  'Key facts, exhibits, and likely arguments.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
