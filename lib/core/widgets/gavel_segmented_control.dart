import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';

class GavelSegmentedControl<T> extends StatelessWidget {
  const GavelSegmentedControl({
    super.key,
    required this.selected,
    required this.options,
    required this.keyFor,
    this.compactLabels = const {},
    required this.onChanged,
  });
  final T selected;
  final Map<T, String> options;
  final Map<T, String> compactLabels;
  final ValueKey<String> Function(T) keyFor;
  final ValueChanged<T> onChanged;

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
              for (final option in options.entries)
                Expanded(
                  child: Semantics(
                    selected: selected == option.key,
                    child: Tooltip(
                      message: option.value,
                      child: TextButton(
                        key: keyFor(option.key),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xs,
                            vertical: Spacing.sm,
                          ),
                          backgroundColor: selected == option.key
                              ? scheme.primary
                              : Colors.transparent,
                          foregroundColor: selected == option.key
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Radii.card - Spacing.xs,
                            ),
                          ),
                        ),
                        onPressed: selected == option.key
                            ? () {}
                            : () => onChanged(option.key),
                        child: Text(
                          compact
                              ? compactLabels[option.key] ?? option.value
                              : option.value,
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
