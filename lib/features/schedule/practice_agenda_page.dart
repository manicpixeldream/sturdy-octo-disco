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
    final tasks = context.watch<TaskController>();
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
            Text(
              !session.persistsLocalWork
                  ? 'Plan the order of rehearsal. Your agenda draft stays in this session.'
                  : session.sharedWorkspace
                  ? 'Plan the order of rehearsal. Your agenda draft is saved in this browser.'
                  : 'Plan the order of rehearsal. Agenda items and follow-up tasks are saved in this browser.',
            ),
            const SizedBox(height: Spacing.lg),
            ..._agenda(context, schedule, cases, exams, caseId),
            const SizedBox(height: Spacing.lg),
            if (team.loadFailed || tasks.loadFailed)
              LoadFailure(
                title: 'Could not load follow-up assignments',
                onRetry: () async {
                  await Future.wait([
                    if (team.loadFailed) team.load(),
                    if (tasks.loadFailed) tasks.load(),
                  ]);
                },
              )
            else if (!team.isLoaded || !tasks.isLoaded)
              const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading follow-up assignments',
                ),
              )
            else if (session.sharedWorkspace &&
                team.byId(session.currentTeammateId) == null)
              const Text(
                'Ask your team lead to add you to the roster to assign follow-ups.',
              )
            else if (team.teammates.isEmpty)
              const Text('There are no teammates to assign a follow-up to.')
            else
              OutlinedButton.icon(
                key: const ValueKey('practice_add_follow_up'),
                icon: const Icon(Icons.add_task),
                label: const Text('Assign a follow-up task'),
                onPressed: () async {
                  final today = session.clock.now();
                  final dueDate = practice.endsAt.isAfter(today)
                      ? practice.endsAt
                      : today;
                  final eligible = session.sharedWorkspace
                      ? team.teammates
                            .where(
                              (member) =>
                                  practice.participantIds.contains(member.id),
                            )
                            .toList()
                      : team.teammates;
                  if (eligible.isEmpty) return;
                  final saved = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => PracticeFollowUpDialog(
                      teammates: eligible,
                      currentTeammateId: session.currentTeammateId,
                      today: today,
                      initialDueDate: dueDate,
                      onSave: (title, assigneeId, due) async {
                        final current = schedule.sessionById(sessionId);
                        if (cases.activeCase?.id != caseId ||
                            current == null ||
                            (session.sharedWorkspace &&
                                (!current.participantIds.contains(assigneeId) ||
                                    !current.participantIds.contains(
                                      session.currentTeammateId,
                                    )))) {
                          return false;
                        }
                        return tasks.createPracticeFollowUp(
                          sessionId,
                          title,
                          assigneeId,
                          due,
                        );
                      },
                    ),
                  );
                  if (context.mounted && saved == true) {
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
