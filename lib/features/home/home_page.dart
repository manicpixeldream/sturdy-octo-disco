import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/keys.dart';
import '../../core/router/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(me == null ? 'Home' : '$greeting, ${me.firstName}'),
      ),
      body: loaded
          ? ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.xxl,
              ),
              children: [
                ActiveCaseCard(
                  key: GavelKeys.homeActiveCase,
                  caseFile: caseCtrl.activeCase!,
                  daysUntilTrial: caseCtrl.daysUntilTrial,
                  readiness: tasks.teamReadiness,
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        key: GavelKeys.homeStatExhibits,
                        value: '${caseCtrl.exhibits.length}',
                        label: 'Exhibits',
                        icon: Icons.folder_outlined,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: StatTile(
                        key: GavelKeys.homeStatWitnesses,
                        value: '${caseCtrl.witnesses.length}',
                        label: 'Witnesses',
                        icon: Icons.record_voice_over_outlined,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: StatTile(
                        key: GavelKeys.homeStatTasks,
                        value: '${tasks.tasks.length}',
                        label: 'Team tasks',
                        icon: Icons.checklist,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                AskCaseCard(
                  key: GavelKeys.homeAskCase,
                  onTap: () => context.go(Routes.research),
                ),
                const SectionHeader(title: 'Your assignments'),
                ...[
                  for (final task in tasks.tasksFor(session.currentTeammateId))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: AssignmentTile(
                        key: GavelKeys.homeAssignment(task.id),
                        task: task,
                        dueLabel: dueLabel(task.dueDate, session.clock.now()),
                      ),
                    ),
                ],
                TeamReadinessCard(
                  key: GavelKeys.homeTeamReadiness,
                  readiness: tasks.teamReadiness,
                  doneCount: tasks.doneCount,
                  taskCount: tasks.tasks.length,
                  teammates: team.teammates,
                  readinessFor: tasks.readinessFor,
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
