import 'package:material_ui/material_ui.dart';

import '../theme/gavel_colors.dart';
import '../theme/spacing.dart';

enum GavelStatus {
  ready('Ready', GavelColors.ready),
  inProgress('In progress', GavelColors.inProgress),
  flagged('Flagged', GavelColors.flagged),
  info('Info', GavelColors.info);

  const GavelStatus(this.label, this.color);

  final String label;
  final Color color;
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.label});

  final GavelStatus status;

  /// Overrides the status's default label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(status.color, GavelColors.white, 0.45)!
        : status.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacing.xs + 2),
          Text(
            label ?? status.label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
