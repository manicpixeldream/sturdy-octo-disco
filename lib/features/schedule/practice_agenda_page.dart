import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../data/models/timing_rule.dart';
import '../../state/case_controller.dart';
import '../../state/exam_controller.dart';
import '../../state/schedule_controller.dart';
import '../../state/session_controller.dart';
import '../../state/task_controller.dart';
import '../../state/team_controller.dart';
import 'widgets/practice_follow_up_dialog.dart';

class PracticeAgendaPage extends StatelessWidget {
  const PracticeAgendaPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleController>();
    final cases = context.watch<CaseController>();
    final exams = context.watch<ExamController>();
    final team = context.watch<TeamController>();
    final session = context.watch<SessionController>();
    final practice = schedule.sessionById(sessionId);
    final caseId = cases.activeCase?.id;
    return WorkspacePage(
      title: 'Practice agenda',
      leading: BackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.schedule);
          }
        },
      ),
      child: WorkspaceScrollView(
        maxWidth: LayoutTokens.reading,
        children: [
          if (schedule.loadFailed || cases.loadFailed || exams.loadFailed)
            LoadFailure(
              title: 'Practice agenda unavailable',
              onRetry: () async {
                if (schedule.loadFailed) await schedule.load();
                if (cases.loadFailed) await cases.load();
                if (exams.loadFailed) await exams.load();
              },
            )
          else if (!schedule.isLoaded || !cases.isLoaded || !exams.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (practice == null ||
              caseId == null ||
              !practice.participantIds.contains(session.currentTeammateId))
            const Text('This practice session is unavailable.')
          else ...[
            Text(
              practice.title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: Spacing.md),
            const Text(
              'Plan the order of rehearsal. Agenda items and follow-up tasks are saved for this session.',
            ),
            const SizedBox(height: Spacing.lg),
            ..._agenda(context, schedule, cases, exams, caseId),
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              key: const ValueKey('practice_add_follow_up'),
              icon: const Icon(Icons.add_task),
              label: const Text('Assign a follow-up task'),
              onPressed: team.teammates.isEmpty
                  ? null
                  : () async {
                      final tasks = context.read<TaskController>();
                      final result =
                          await showDialog<({String title, String assigneeId})>(
                            context: context,
                            builder: (_) => PracticeFollowUpDialog(
                              teammates: team.teammates,
                              currentTeammateId: session.currentTeammateId,
                            ),
                          );
                      if (context.mounted && result != null) {
                        final dueDate =
                            practice.endsAt.isAfter(session.clock.now())
                            ? practice.endsAt
                            : session.clock.now();
                        tasks.addFollowUp(
                          result.title,
                          result.assigneeId,
                          dueDate,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Follow-up added to the teammate’s task list.',
                            ),
                          ),
                        );
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _agenda(
    BuildContext context,
    ScheduleController schedule,
    CaseController cases,
    ExamController exams,
    String caseId,
  ) {
    final items = schedule.agenda(caseId, sessionId);
    final available = <AgendaItem>[
      (witnessId: null, phase: TrialPhase.opening),
      for (final witness in cases.witnesses)
        for (final phase in const [TrialPhase.direct, TrialPhase.cross])
          (witnessId: witness.id, phase: phase),
      (witnessId: null, phase: TrialPhase.closing),
    ].where((item) => !items.contains(item)).toList();

    String label(AgendaItem item) => item.witnessId == null
        ? item.phase.label
        : '${cases.witnessById(item.witnessId!)?.name ?? 'Unavailable witness'} · ${item.phase.label}';

    return [
      if (items.isEmpty)
        const Text('Add a script or argument to start the agenda.'),
      for (final (index, item) in items.indexed)
        _itemTile(
          context,
          cases,
          exams,
          item,
          index,
          label(item),
          items,
          schedule,
          caseId,
        ),
      PopupMenuButton<AgendaItem>(
        key: const ValueKey('practice_add_agenda_item'),
        enabled: available.isNotEmpty,
        tooltip: 'Add to rehearsal',
        onSelected: (item) =>
            schedule.setAgenda(caseId, sessionId, [...items, item]),
        itemBuilder: (_) => [
          for (final item in available)
            PopupMenuItem(value: item, child: Text(label(item))),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Text('+ Add script or argument'),
        ),
      ),
    ];
  }

  Widget _itemTile(
    BuildContext context,
    CaseController cases,
    ExamController exams,
    AgendaItem item,
    int index,
    String title,
    List<AgendaItem> items,
    ScheduleController schedule,
    String caseId,
  ) {
    final witnessId = item.witnessId;
    final witness = witnessId == null ? null : cases.witnessById(witnessId);
    final script = witness == null
        ? null
        : exams.scriptFor(witness.id, item.phase);
    final rule = cases.timingRules
        .where((rule) => rule.phase == item.phase)
        .firstOrNull;
    final timing = rule == null
        ? 'Timing rule unavailable'
        : '${rule.minutes} min limit';
    final details = script == null || witness == null
        ? timing
        : '${script.status.label} · ${script.questions.where((q) => q.flagged).length} flagged · '
              '${script.estimatedSeconds}s draft · ${exams.budgetSeconds(witness.id, item.phase)}s ${rule?.sharedAcrossWitnesses == true ? 'side total' : 'estimated'} / $timing'
              '${exams.overBudget(witness.id, item.phase) ? ' · Over time' : ''}';
    final route = witnessId == null
        ? Routes.argument(item.phase.name)
        : Routes.exam(witnessId, phase: item.phase.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. $title',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(details),
            if (script != null && witnessId != null)
              for (final question in script.questions.where(
                (question) => question.flagged,
              ))
                TextButton(
                  onPressed: () => context.push(
                    Routes.exam(
                      witnessId,
                      phase: item.phase.name,
                      questionId: question.id,
                    ),
                  ),
                  child: Text('Review: ${question.text}'),
                ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () => context.push(route),
                  child: const Text('Open draft'),
                ),
                IconButton(
                  tooltip: 'Move earlier',
                  onPressed: index == 0
                      ? null
                      : () {
                          final reordered = [...items]
                            ..removeAt(index)
                            ..insert(index - 1, item);
                          schedule.setAgenda(caseId, sessionId, reordered);
                        },
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Remove from agenda',
                  onPressed: () => schedule.setAgenda(
                    caseId,
                    sessionId,
                    [...items]..removeAt(index),
                  ),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
