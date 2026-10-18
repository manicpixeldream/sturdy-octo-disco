import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';

class ColorSwatchTile extends StatelessWidget {
  const ColorSwatchTile({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Radii.card / 2),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(name, style: theme.textTheme.labelMedium),
          Text('#$hex', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
