import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import 'role_metadata.dart';
import '../../../data/models/trial_role.dart';
import '../../../data/models/teammate.dart';

class RoleTile extends StatelessWidget {
  const RoleTile({
    super.key,
    required this.role,
    required this.assignee,
    required this.onAssign,
  });
  final TrialRole role;
  final Teammate? assignee;
  final VoidCallback onAssign;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge!;
    final titleHeight =
        MediaQuery.textScalerOf(context).scale(titleStyle.fontSize!) *
        (titleStyle.height ?? 1.2) *
        2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: GavelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: titleHeight),
                  child: Text(role.title, style: titleStyle),
                ),
                const SizedBox(height: Spacing.md),
                RoleMetadata(side: role.side, assigned: assignee != null),
                const SizedBox(height: Spacing.md),
                Text(assignee?.name ?? 'No teammate assigned'),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${role.responsibilities.length} preparation responsibilities',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md),
              child: TextButton(
                key: ValueKey('assign_role_${role.id}'),
                onPressed: onAssign,
                child: Text(
                  assignee == null ? 'Assign role' : 'View assignment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
