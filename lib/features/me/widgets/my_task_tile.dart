import 'package:material_ui/material_ui.dart';

import '../../../core/dates.dart';
import '../../../core/theme/spacing.dart';
import '../../../data/models/task_item.dart';

class MyTaskTile extends StatelessWidget {
  const MyTaskTile({
    super.key,
    required this.task,
    required this.today,
    required this.saving,
    required this.failed,
    required this.onChanged,
  });
  final TaskItem task;
  final DateTime today;
  final bool saving, failed;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.md),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            key: ValueKey('my_task_${task.id}'),
            value: task.isDone,
            onChanged: saving ? null : (value) => onChanged(value!),
            title: Text(task.title),
            subtitle: Text(
              saving
                  ? 'Saving…'
                  : task.isDone
                  ? 'Complete'
                  : dueLabel(task.dueDate, today),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Could not save this change. Your task is unchanged.',
                  ),
                  TextButton(
                    key: ValueKey('retry_task_${task.id}'),
                    onPressed: saving ? null : () => onChanged(!task.isDone),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
