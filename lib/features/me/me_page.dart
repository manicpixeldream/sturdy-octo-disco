import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/spacing.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/widgets/workspace_columns.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/load_failure.dart';
import '../../state/team_controller.dart';
import '../../state/task_controller.dart';
import '../../state/role_controller.dart';
import '../../state/session_controller.dart';
import 'widgets/my_task_tile.dart';
import 'widgets/quick_access_grid.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final team = context.watch<TeamController>();
    final tasks = context.watch<TaskController>();
    final roles = context.watch<RoleController>();
    final member = team.byId(session.currentTeammateId);
    final mine = tasks.tasksFor(session.currentTeammateId);
    final done = mine.where((t) => t.isDone).length;
    return WorkspacePage(
      title: 'Profile',
      child: WorkspaceScrollView(
        children: [
          if (team.loadFailed || tasks.loadFailed || roles.loadFailed)
            LoadFailure(
              title: 'Your preparation unavailable',
              onRetry: () {
                team.load();
                tasks.load();
                roles.load();
              },
            )
          else if (!team.isLoaded || !tasks.isLoaded || !roles.isLoaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: member?.name ?? 'You', size: 56),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member?.name ?? 'Your preparation',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const Text('Your preparation, in one place.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            Wrap(
              spacing: Spacing.xxl,
              runSpacing: Spacing.md,
              children: [
                StatTile(
                  key: const ValueKey('me_task_count'),
                  value: '${mine.length}',
                  label: 'Assigned tasks',
                ),
                StatTile(
                  key: const ValueKey('me_done_count'),
                  value: '$done',
                  label: 'Complete',
                ),
                StatTile(value: '${mine.length - done}', label: 'Remaining'),
              ],
            ),
            const SizedBox(height: Spacing.md),
            ProgressBar(value: tasks.readinessFor(session.currentTeammateId)),
            const SizedBox(height: Spacing.sm),
            Text(
              '$done of ${mine.length} personal tasks complete',
              key: const ValueKey('me_completion'),
            ),
            WorkspaceColumns(
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'My tasks'),
                  if (mine.isEmpty)
                    const Text(
                      'No tasks assigned yet. Visit Team to review your roles.',
                    ),
                  for (final task in mine)
                    MyTaskTile(
                      task: task,
                      today: session.clock.now(),
                      saving: tasks.isSaving(task.id),
                      failed: tasks.saveFailed(task.id),
                      onChanged: (value) => tasks.setCompleted(task.id, value),
                    ),
                ],
              ),
              secondary: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Quick access'),
                  QuickAccessGrid(),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
            const Text(
              'Demo profile · Changes last for this app session. Reloading resets task completion and assignments.',
            ),
          ],
        ],
      ),
    );
  }
}
