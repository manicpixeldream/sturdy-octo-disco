import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../data/models/teammate.dart';

class TeammateSuggestionTile extends StatelessWidget {
  const TeammateSuggestionTile({
    super.key,
    required this.member,
    required this.openTasks,
    required this.selected,
    required this.onSelect,
  });
  final Teammate member;
  final int openTasks;
  final bool selected;
  final VoidCallback? onSelect;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
    child: OutlinedButton(
      key: ValueKey('select_${member.id}'),
      onPressed: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Row(
          children: [
            InitialsAvatar(name: member.name),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name),
                  Text('$openTasks unfinished tasks'),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              semanticLabel: selected ? 'Selected' : 'Not selected',
            ),
          ],
        ),
      ),
    ),
  );
}
