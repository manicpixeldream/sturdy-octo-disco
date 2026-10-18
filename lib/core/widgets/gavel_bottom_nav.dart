import 'package:material_ui/material_ui.dart';

import '../keys.dart';
import '../theme/spacing.dart';
import 'gavel_nav_button.dart';
import 'gavel_nav_item.dart';

class GavelBottomNav extends StatelessWidget {
  const GavelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<GavelNavItem> items = [
    (key: GavelKeys.navHome, label: 'Home', icon: Icons.home_outlined),
    (key: GavelKeys.navCase, label: 'Case', icon: Icons.folder_outlined),
    (
      key: GavelKeys.navResearch,
      label: 'AI',
      icon: Icons.auto_awesome_outlined,
    ),
    (key: GavelKeys.navTeam, label: 'Team', icon: Icons.groups_outlined),
    (key: GavelKeys.navMe, label: 'Profile', icon: Icons.person_outline),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64 + MediaQuery.textScalerOf(context).scale(12),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final button = GavelNavButton(
                        key: items[i].key,
                        item: items[i],
                        selected: i == currentIndex,
                        onPressed: () => onTap(i),
                      );
                      // Keep resize frames safe without shrinking normal touch targets.
                      if (constraints.maxHeight < 56 ||
                          constraints.maxWidth < 48) {
                        return FittedBox(
                          child: SizedBox(width: 76, height: 72, child: button),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.xs,
                        ),
                        child: button,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
