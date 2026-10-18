import 'package:material_ui/material_ui.dart';

import '../keys.dart';
import '../theme/gavel_theme.dart';
import '../theme/spacing.dart';

typedef GavelNavItem = ({
  ValueKey<String> key,
  String label,
  IconData icon,
  IconData selectedIcon,
});

class GavelBottomNav extends StatelessWidget {
  const GavelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// In branch order. The middle item is drawn as the raised Research button.
  static const List<GavelNavItem> items = [
    (
      key: GavelKeys.navHome,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    (
      key: GavelKeys.navCase,
      label: 'Case',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
    ),
    (
      key: GavelKeys.navResearch,
      label: 'Research',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
    ),
    (
      key: GavelKeys.navTeam,
      label: 'Team',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    (
      key: GavelKeys.navMe,
      label: 'Me',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  static const int _raisedIndex = 2;

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: i == _raisedIndex
                      ? _buildRaisedItem(theme, i)
                      : _buildItem(theme, i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(ThemeData theme, int index) {
    final item = items[index];
    final selected = index == currentIndex;
    final color = selected
        ? GavelTheme.accent(theme)
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        key: item.key,
        onTap: () => onTap(index),
        // Scales down instead of overflowing when squeezed (tiny windows,
        // mid-resize frames, large text scale).
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? item.selectedIcon : item.icon, color: color),
                const SizedBox(height: Spacing.xs),
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaisedItem(ThemeData theme, int index) {
    final item = items[index];
    final selected = index == currentIndex;
    final scheme = theme.colorScheme;
    return Center(
      child: Semantics(
        label: item.label,
        selected: selected,
        button: true,
        child: Material(
          key: item.key,
          color: scheme.primary,
          elevation: selected ? 6 : 3,
          shadowColor: scheme.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card - 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(index),
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
