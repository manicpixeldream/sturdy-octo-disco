import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';

class TeamRoleFilter extends StatelessWidget {
  const TeamRoleFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scheme = Theme.of(context).colorScheme;
      final compact =
          constraints.maxWidth < 260 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.5;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xs),
          child: Row(
            children: [
              for (final label in ['Prosecution', 'Defense'])
                Expanded(
                  child: Semantics(
                    selected: selected == label,
                    child: Tooltip(
                      message: label,
                      child: TextButton(
                        key: ValueKey('team_filter_$label'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xs,
                            vertical: Spacing.sm,
                          ),
                          backgroundColor: selected == label
                              ? scheme.primary
                              : Colors.transparent,
                          foregroundColor: selected == label
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Radii.card - Spacing.xs,
                            ),
                          ),
                        ),
                        onPressed: selected == label
                            ? () {}
                            : () => onChanged(label),
                        child: Text(
                          compact
                              ? switch (label) {
                                  'Prosecution' => 'Pros.',
                                  'Defense' => 'Def.',
                                  _ => label,
                                }
                              : label,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
