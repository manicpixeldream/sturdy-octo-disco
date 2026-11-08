import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/dates.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/widgets/status_pill.dart';
import '../../state/task_controller.dart';
import '../../state/team_controller.dart';
import '../../state/role_controller.dart';
import '../../state/session_controller.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});
  final String taskId;
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final team = context.watch<TeamController>();
    final roles = context.watch<RoleController>();
    final session = context.watch<SessionController>();
    final task = tasks.tasks.where((t) => t.id == taskId).firstOrNull;
    return WorkspacePage(
      title: 'Task',
      leading: IconButton(
        key: const ValueKey('task_detail_back'),
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Routes.teamChat),
      ),
      child: WorkspaceScrollView(
        maxWidth: LayoutTokens.reading,
        children: [
          if (tasks.loadFailed || team.loadFailed || roles.loadFailed)
            LoadFailure(
              title: 'Task unavailable',
              onRetry: () {
                tasks.load();
                team.load();
                roles.load();
              },
            )
          else if (!tasks.isLoaded || !team.isLoaded || !roles.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (task == null)
            const Text(
              'This task is no longer available. Return to chat to choose another reference.',
            )
          else ...[
            Text(
              task.title,
              key: const ValueKey('task_detail_title'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Assigned to ${team.byId(task.assigneeId)?.name ?? 'a former teammate'}',
            ),
            const SizedBox(height: Spacing.md),
            StatusPill(
              status: task.isDone ? GavelStatus.ready : GavelStatus.inProgress,
              label: task.isDone
                  ? 'Complete'
                  : dueLabel(task.dueDate, session.clock.now()),
            ),
            const SizedBox(height: Spacing.xl),
            if (task.assigneeId == session.currentTeammateId)
              OutlinedButton(
                key: const ValueKey('task_open_checklist'),
                onPressed: () => context.go(Routes.me),
                child: const Text('Open my checklist'),
              )
            else
              const Text(
                'This is a teammate’s task. Task completion is managed from their personal checklist.',
              ),
          ],
        ],
      ),
    );
  }
}
