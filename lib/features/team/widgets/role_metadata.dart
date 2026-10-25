import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../core/widgets/status_pill.dart';

/// Reserve the longest label's width on both sides, including text scaling.
class RoleMetadata extends StatelessWidget {
  const RoleMetadata({super.key, required this.side, required this.assigned});
  final String side;
  final bool assigned;
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!;
    double width(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final result = painter.width;
      painter.dispose();
      return result;
    }

    final sideWidth = width('Prosecution') + Spacing.md * 2;
    final statusWidth =
        width('Open role') + 6 + Spacing.xs + 2 + Spacing.xs * 2;
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: sideWidth,
          child: TagChip(key: const ValueKey('role_side_bubble'), label: side),
        ),
        SizedBox(
          width: statusWidth,
          child: StatusPill(
            key: const ValueKey('role_status'),
            status: assigned ? GavelStatus.info : GavelStatus.inProgress,
            label: assigned ? 'Assigned' : 'Open role',
          ),
        ),
      ],
    );
  }
}
