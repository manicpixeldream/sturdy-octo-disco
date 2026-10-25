import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/theme/spacing.dart';
import '../../../data/models/teammate.dart';
import '../../../data/models/task_item.dart';

class MemberTaskQueue extends StatelessWidget {
  const MemberTaskQueue({
    super.key,
    required this.member,
    required this.tasks,
    required this.roleCount,
  });
  final Teammate member;
  final List<TaskItem> tasks;
  final int roleCount;
  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.isDone).length;
    final scheme = Theme.of(context).colorScheme;
    final border = RoundedRectangleBorder(
      side: BorderSide(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(Radii.card),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: ExpansionTile(
        shape: border,
        collapsedShape: border,
        backgroundColor: scheme.surface,
        collapsedBackgroundColor: scheme.surface,
        clipBehavior: Clip.antiAlias,
        key: ValueKey('member_queue_${member.id}'),
        leading: InitialsAvatar(name: member.name),
        title: Text(member.name),
        subtitle: Text(
          '$done/${tasks.length} tasks complete · $roleCount roles',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: ProgressBar(value: tasks.isEmpty ? 0 : done / tasks.length),
          ),
          if (tasks.isEmpty) const Text('No preparation tasks assigned.'),
          for (final task in tasks)
            ListTile(
              key: ValueKey('queue_task_${task.id}'),
              leading: Icon(
                task.isDone
                    ? Icons.check_circle_outline
                    : Icons.circle_outlined,
                semanticLabel: task.isDone ? 'Complete' : 'Unfinished',
              ),
              title: Text(task.title),
            ),
        ],
      ),
    );
  }
}
