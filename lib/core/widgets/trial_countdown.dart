import 'package:material_ui/material_ui.dart';

import '../dates.dart';
import '../theme/spacing.dart';

/// A compact deadline label that sits quietly within editorial headers.
class TrialCountdown extends StatelessWidget {
  const TrialCountdown({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.05),
          theme.scaffoldBackgroundColor,
        ),
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs + 2,
        ),
        child: Text(
          trialCountdownLabel(days),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
