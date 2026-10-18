import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../data/models/affidavit.dart';
import '../../../data/models/witness.dart';

class WitnessCard extends StatelessWidget {
  const WitnessCard({
    super.key,
    required this.affidavit,
    required this.witness,
    required this.onOpen,
  });

  final Affidavit affidavit;
  final Witness? witness;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Read affidavit by ${affidavit.title}',
      child: GavelCard(
        color: theme.colorScheme.surface,
        onTap: onOpen,
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    affidavit.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(
                  Icons.arrow_outward,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            if (witness != null) ...[
              Text(witness!.description, style: theme.textTheme.bodySmall),
              const SizedBox(height: Spacing.sm),
              Text(
                witness!.side.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            Text(
              affidavit.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
