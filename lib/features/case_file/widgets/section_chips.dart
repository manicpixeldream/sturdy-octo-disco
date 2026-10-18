import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/gavel_theme.dart';
import '../../../core/theme/spacing.dart';

enum CaseSection {
  overview('Overview'),
  brief('Brief'),
  affidavits('Affidavits'),
  exhibits('Exhibits'),
  stipulations('Stipulations'),
  rules('Rules');

  const CaseSection(this.label);
  final String label;
}

/// Secondary sections stay reachable while primary tabs scroll on small screens.
class SectionChips extends StatelessWidget {
  const SectionChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final CaseSection selected;
  final ValueChanged<CaseSection> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final accent = GavelTheme.accent(theme);
      final primary = [
        CaseSection.overview,
        CaseSection.brief,
        CaseSection.affidavits,
        if (constraints.maxWidth >= 600) CaseSection.exhibits,
      ];
      final secondary = CaseSection.values
          .where((section) => !primary.contains(section))
          .toList();
      final moreSelected = secondary.contains(selected);
      return DecoratedBox(
        key: GavelKeys.caseSections,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final section in primary)
                      Semantics(
                        selected: selected == section,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: selected == section
                                    ? accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: TextButton(
                            key: GavelKeys.caseSection(section.name),
                            style: TextButton.styleFrom(
                              foregroundColor: selected == section
                                  ? accent
                                  : theme.colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                                vertical: Spacing.lg,
                              ),
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: () => onSelected(section),
                            child: Text(
                              section.label,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Semantics(
              selected: moreSelected,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: moreSelected ? accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: PopupMenuButton<CaseSection>(
                  key: const ValueKey('case_more'),
                  tooltip: moreSelected
                      ? 'More case sections (${selected.label} selected)'
                      : 'More case sections',
                  onSelected: onSelected,
                  initialValue: moreSelected ? selected : null,
                  itemBuilder: (_) => [
                    for (final section in secondary)
                      PopupMenuItem(
                        value: section,
                        key: GavelKeys.caseSection(section.name),
                        child: Text(section.label),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.lg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: moreSelected
                                ? accent
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: moreSelected
                              ? accent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
