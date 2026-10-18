import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';
import 'gavel_bottom_nav.dart';
import 'gavel_nav_button.dart';

class GavelSidebar extends StatelessWidget {
  const GavelSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.expanded,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      key: const ValueKey('workspace_sidebar'),
      width: expanded ? 216 : 88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? Spacing.lg : Spacing.sm,
              vertical: Spacing.xxl,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: Text(
                      expanded ? 'Gavel' : 'G.',
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Spacing.md,
                        top: Spacing.xs,
                      ),
                      child: Text(
                        'THE PREPARATION WORKSPACE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: Spacing.xxxl),
                  for (var i = 0; i < GavelBottomNav.items.length; i++) ...[
                    GavelNavButton(
                      key: GavelBottomNav.items[i].key,
                      item: GavelBottomNav.items[i],
                      selected: i == currentIndex,
                      horizontal: expanded,
                      onPressed: () => onTap(i),
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
