import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/keys.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/router/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/workspace_columns.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../state/case_controller.dart';
import '../../state/session_controller.dart';
import '../../state/task_controller.dart';
import '../../state/team_controller.dart';
import 'widgets/active_case_card.dart';
import 'widgets/ask_case_card.dart';
import 'widgets/assignment_tile.dart';
import 'widgets/team_readiness_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final caseCtrl = context.watch<CaseController>();
    final team = context.watch<TeamController>();
    final tasks = context.watch<TaskController>();
    final loaded = caseCtrl.isLoaded && team.isLoaded && tasks.isLoaded;
    final me = team.byId(session.currentTeammateId);
    final greeting = greetingFor(session.clock.now());

    return WorkspacePage(
      title: me == null ? 'Home' : '$greeting, ${me.firstName}',
      child: caseCtrl.loadFailed || team.loadFailed || tasks.loadFailed
          ? Center(
              child: LoadFailure(
                title: 'Could not load your workspace',
                onRetry: () async {
                  await Future.wait([
                    if (caseCtrl.loadFailed) caseCtrl.load(),
                    if (team.loadFailed) team.load(),
                    if (tasks.loadFailed) tasks.load(),
                  ]);
                },
              ),
            )
          : loaded
          ? WorkspaceScrollView(
              storageKey: const PageStorageKey('home_scroll'),
              children: [
                ActiveCaseCard(
                  key: GavelKeys.homeActiveCase,
                  caseFile: caseCtrl.activeCase!,
                  daysUntilTrial: caseCtrl.daysUntilTrial,
                  readiness: tasks.teamReadiness,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Demo schedule · dates reset on each launch',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        key: GavelKeys.homeStatExhibits,
                        value: '${caseCtrl.exhibits.length}',
                        label: 'Exhibits',
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        key: GavelKeys.homeStatWitnesses,
                        value: '${caseCtrl.witnesses.length}',
                        label: 'Witnesses',
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        key: GavelKeys.homeStatTasks,
                        value: '${tasks.tasks.length}',
                        label: 'Team tasks',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xxl),
                const Divider(),
                const SizedBox(height: Spacing.lg),
                WorkspaceColumns(
                  primary: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Your assignments'),
                      for (final task in tasks.tasksFor(
                        session.currentTeammateId,
                      ))
                        AssignmentTile(
                          key: GavelKeys.homeAssignment(task.id),
                          task: task,
                          dueLabel: dueLabel(task.dueDate, session.clock.now()),
                        ),
                    ],
                  ),
                  secondary: Column(
                    children: [
                      AskCaseCard(
                        key: GavelKeys.homeAskCase,
                        onTap: () => context.go(Routes.research),
                      ),
                      const SizedBox(height: Spacing.xxl),
                      TeamReadinessCard(
                        key: GavelKeys.homeTeamReadiness,
                        readiness: tasks.teamReadiness,
                        doneCount: tasks.doneCount,
                        taskCount: tasks.tasks.length,
                        teammates: team.teammates,
                        readinessFor: tasks.readinessFor,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
