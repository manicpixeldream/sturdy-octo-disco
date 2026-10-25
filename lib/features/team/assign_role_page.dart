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
import '../../core/widgets/gavel_card.dart';
import '../../core/widgets/tag_chip.dart';
import '../../state/teammate_matcher.dart';
import 'widgets/teammate_suggestion_tile.dart';

class AssignRolePage extends StatefulWidget {
  const AssignRolePage({super.key, required this.roleId});
  final String roleId;
  @override
  State<AssignRolePage> createState() => _AssignRolePageState();
}

class _AssignRolePageState extends State<AssignRolePage> {
  String? selectedId;
  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleController>();
    final team = context.watch<TeamController>();
    final tasks = context.watch<TaskController>();
    final role = roles.byId(widget.roleId);
    final assignment = roles.assignmentFor(widget.roleId);
    final selected = selectedId == null ? null : team.byId(selectedId!);
    return WorkspacePage(
      title: 'Assign role',
      leading: IconButton(
        key: const ValueKey('assign_back'),
        tooltip: 'Back to Team',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/team'),
      ),
      child: WorkspaceScrollView(
        children: [
          if (roles.loadFailed || team.loadFailed || tasks.loadFailed)
            LoadFailure(
              title: 'Assignment unavailable',
              onRetry: () {
                roles.load();
                team.load();
                tasks.load();
              },
            )
          else if (!roles.isLoaded || !team.isLoaded || !tasks.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (role == null)
            const Text(
              'This role could not be found. Return to Team to choose a role.',
            )
          else ...[
            Text(role.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                TagChip(label: role.side),
                TagChip(label: role.isWitness ? 'Witness' : 'Attorney'),
              ],
            ),
            const SectionHeader(title: 'Responsibilities'),
            const Text(
              'All responsibilities are added as unfinished tasks, due on the demo trial date.',
            ),
            GavelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final responsibility in role.responsibilities)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.checklist, size: 20),
                          const SizedBox(width: Spacing.sm),
                          Expanded(child: Text(responsibility)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (assignment != null) ...[
              const SectionHeader(title: 'Role assigned'),
              Text(
                'Assigned to ${team.byId(assignment.teammateId)?.name ?? assignment.teammateId}. Responsibilities are in their task queue.',
              ),
            ] else ...[
              const SectionHeader(title: 'Suggested teammates'),
              const Text(
                'Demo suggestions rank the fewest unfinished tasks first, then name. No AI or skill assessment is used. Teammates may hold multiple roles; review trial scheduling before assigning.',
              ),
              const SizedBox(height: Spacing.md),
              for (final member in TeammateMatcher.rank(
                team.teammates,
                tasks.tasks,
              ))
                TeammateSuggestionTile(
                  member: member,
                  openTasks: tasks
                      .tasksFor(member.id)
                      .where((t) => !t.isDone)
                      .length,
                  selected: selectedId == member.id,
                  onSelect: roles.isSaving
                      ? null
                      : () => setState(() => selectedId = member.id),
                ),
              if (team.teammates.isEmpty)
                const Text('No teammates available for this role.'),
              if (roles.saveFailed)
                const Text(
                  'Assignment could not be saved. Try again.',
                  key: ValueKey('assign_error'),
                ),
              const SizedBox(height: Spacing.lg),
              FilledButton(
                key: const ValueKey('assign_role_submit'),
                onPressed: selected == null || roles.isSaving
                    ? null
                    : () async {
                        final success = await roles.assign(
                          role.id,
                          selected.id,
                        );
                        if (!context.mounted || !success) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Role assigned and responsibilities added. No notification sent.',
                            ),
                          ),
                        );
                      },
                child: Text(
                  roles.isSaving
                      ? 'Assigning…'
                      : selected == null
                      ? 'Select a teammate'
                      : 'Assign ${selected.firstName}',
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            const Text(
              'Assignments are saved for this session only. Reloading resets them. Team notifications arrive with the shared backend.',
            ),
          ],
        ],
      ),
    );
  }
}
