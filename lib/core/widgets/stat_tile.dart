import 'package:material_ui/material_ui.dart';

import '../theme/gavel_theme.dart';
import '../theme/spacing.dart';
import 'gavel_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = GavelTheme.accent(theme);
    return GavelCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: Spacing.sm),
          ],
          Text(value, style: theme.textTheme.displaySmall),
          const SizedBox(height: Spacing.xs),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
