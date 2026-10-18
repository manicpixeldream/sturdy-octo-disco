import 'package:material_ui/material_ui.dart';

import '../theme/gavel_theme.dart';
import '../theme/spacing.dart';
import 'gavel_nav_item.dart';

class GavelNavButton extends StatelessWidget {
  const GavelNavButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onPressed,
    this.horizontal = false,
  });

  final GavelNavItem item;
  final bool selected;
  final VoidCallback onPressed;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? GavelTheme.accent(theme)
        : theme.colorScheme.onSurfaceVariant;
    final icon = Icon(item.icon, size: 22);
    final label = Text(
      item.label,
      maxLines: 1,
      style: theme.textTheme.labelMedium?.copyWith(color: color, height: 1.1),
    );
    return Semantics(
      selected: selected,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color,
            backgroundColor: horizontal && selected
                ? color.withValues(alpha: 0.06)
                : Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: horizontal ? Spacing.lg : Spacing.xs,
              vertical: Spacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            minimumSize: const Size(48, 48),
          ),
          child: horizontal
              ? Row(
                  children: [
                    icon,
                    const SizedBox(width: Spacing.md),
                    Flexible(child: label),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: Spacing.xs),
                    FittedBox(fit: BoxFit.scaleDown, child: label),
                    const SizedBox(height: Spacing.xs),
                    Container(
                      height: 2,
                      width: 16,
                      color: selected ? color : Colors.transparent,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
