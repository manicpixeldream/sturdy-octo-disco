import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = 8,
  });

  /// Fraction complete. Values outside 0–1 are clamped.
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(Radii.pill);
    return Semantics(
      value: '${(fraction * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor ?? scheme.outlineVariant,
          borderRadius: radius,
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? scheme.primary,
              borderRadius: radius,
            ),
          ),
        ),
      ),
    );
  }
}
