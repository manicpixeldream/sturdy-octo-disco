import '../../state/session_controller.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/workspace_columns.dart';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spacing.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/widgets/section_header.dart';
import '../../state/team_controller.dart';
import '../../state/task_controller.dart';
import '../../state/role_controller.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/progress_bar.dart';
import 'widgets/member_task_queue.dart';
import 'widgets/role_tile.dart';
import 'widgets/role_grid.dart';
import 'widgets/team_role_filter.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});
  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  String filter = 'Prosecution';
  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamController>();
    final tasks = context.watch<TaskController>();
    final roles = context.watch<RoleController>();
    final shared = context.watch<SessionController>().sharedWorkspace;
    final failed = team.loadFailed || tasks.loadFailed || roles.loadFailed;
    final sideRoles = roles.roles.where((role) => role.side == filter);
    return WorkspacePage(
      title: 'Team',
      child: WorkspaceScrollView(
        children: [
          Text(
            'Prepare as a team.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: Spacing.md),
          const Text('A shared strategy starts with clear responsibilities.'),
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            key: const ValueKey('team_open_chat'),
            onPressed: () => context.push(Routes.teamChat),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Open team chat'),
          ),
          const SizedBox(height: Spacing.lg),
          if (failed)
            LoadFailure(
              title: 'Team unavailable',
              onRetry: () {
                team.load();
                tasks.load();
                roles.load();
              },
            )
          else if (!team.isLoaded || !tasks.isLoaded || !roles.isLoaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            Wrap(
              spacing: Spacing.xxl,
              runSpacing: Spacing.md,
              children: [
                StatTile(value: '${team.teammates.length}', label: 'Teammates'),
                if (!shared)
                  StatTile(
                    key: const ValueKey('team_role_coverage'),
                    value: '${roles.assignments.length}/${roles.roles.length}',
                    label: 'Roles filled',
                  ),
                StatTile(
                  key: const ValueKey('team_completion'),
                  value: '${(tasks.teamReadiness * 100).round()}%',
                  label: 'Tasks complete',
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            ProgressBar(value: tasks.teamReadiness),
            const SizedBox(height: Spacing.sm),
            Text(
              '${tasks.doneCount} of ${tasks.tasks.length} preparation tasks complete. New responsibilities may lower this percentage.',
            ),
            WorkspaceColumns(
              primary: shared
                  ? const Text(
                      'The shared roster and task status are read-only.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Trial roles'),
                        TeamRoleFilter(
                          selected: filter,
                          onChanged: (value) => setState(() => filter = value),
                        ),
                        const SizedBox(height: Spacing.md),
                        for (final (title, group) in [
                          (
                            'Attorneys',
                            sideRoles.where((role) => !role.isWitness),
                          ),
                          (
                            'Witnesses',
                            sideRoles.where((role) => role.isWitness),
                          ),
                        ]) ...[
                          SectionHeader(title: title),
                          if (group.isEmpty)
                            Text(
                              'No ${title.toLowerCase()} listed for $filter.',
                            )
                          else
                            RoleGrid(
                              children: [
                                for (final role in group)
                                  RoleTile(
                                    role: role,
                                    assignee: team.byId(
                                      roles
                                              .assignmentFor(role.id)
                                              ?.teammateId ??
                                          '',
                                    ),
                                    onAssign: () => context.push(
                                      Routes.assignRole(role.id),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
              secondary: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Roster & preparation'),
                  if (team.teammates.isEmpty) const Text('No teammates yet.'),
                  for (final member in team.teammates)
                    MemberTaskQueue(
                      member: member,
                      tasks: tasks.tasksFor(member.id),
                      roleCount: roles.assignments
                          .where((a) => a.teammateId == member.id)
                          .length,
                    ),
                ],
              ),
            ),
            if (!shared) const SectionHeader(title: 'Team coordination'),
            if (!shared)
              const Text(
                'Use Team Chat to link tasks, exhibits, and drafts. Chat and assignments are saved in this browser. No messages or notifications are sent to teammates.',
              ),
          ],
        ],
      ),
    );
  }
}
