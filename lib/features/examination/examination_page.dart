import '../../core/widgets/gavel_segmented_control.dart';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/widgets/workspace_columns.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/load_failure.dart';
import '../../data/models/exam_question.dart';
import '../../data/models/exam_script.dart';
import '../../data/models/timing_rule.dart';
import '../../state/case_controller.dart';
import '../../state/exam_controller.dart';
import '../../state/research_controller.dart';
import '../../state/team_controller.dart';
import '../research/research_context.dart';
import 'widgets/question_editor_sheet.dart';
import 'widgets/goal_editor_sheet.dart';
import 'widgets/question_tile.dart';
import 'widgets/exam_timing_card.dart';

class ExaminationPage extends StatefulWidget {
  const ExaminationPage({
    super.key,
    required this.witnessId,
    this.phase = TrialPhase.direct,
    this.questionId,
  });
  final String witnessId;
  final TrialPhase phase;
  final String? questionId;
  @override
  State<ExaminationPage> createState() => _ExaminationPageState();
}

class _ExaminationPageState extends State<ExaminationPage> {
  final _anchors = <String, GlobalKey>{};
  String? _scrolled;
  @override
  void didUpdateWidget(covariant ExaminationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrolled = null;
  }

  void _editor(
    ExamController exams,
    CaseController cases, [
    ExamQuestion? question,
  ]) {
    final witness = widget.witnessId, phase = widget.phase;
    final questionId = question?.id ?? exams.newQuestionId();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => QuestionEditorSheet(
        questionId: questionId,
        initial: question,
        exhibits: cases.exhibits,
        sourceLabel: (id) =>
            context.read<ResearchController>().sourceById(id)?.title ?? id,
        onSave: (q) => exams.upsertQuestion(witness, phase, q),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseController>();
    final exams = context.watch<ExamController>();
    final research = context.watch<ResearchController>();
    final team = context.watch<TeamController>();
    final witness = cases.witnessById(widget.witnessId);
    final script = witness == null
        ? null
        : exams.scriptFor(widget.witnessId, widget.phase);
    final requested = widget.questionId;
    final token = '${widget.witnessId}:${widget.phase.name}:$requested';
    if (requested != null &&
        _scrolled != token &&
        script?.questions.any((q) => q.id == requested) == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _anchors[requested]?.currentContext;
        if (target != null) {
          _scrolled = token;
          Scrollable.ensureVisible(target, alignment: .1);
        }
      });
    }
    return WorkspacePage(
      title: 'Examination builder',
      leading: IconButton(
        key: const ValueKey('exam_back'),
        tooltip: 'Back to case',
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Routes.caseFile),
      ),
      child: WorkspaceScrollView(
        storageKey: PageStorageKey(
          'exam_${widget.witnessId}_${widget.phase.name}',
        ),
        children: [
          if (cases.loadFailed || exams.loadFailed)
            LoadFailure(
              title: 'Examination unavailable',
              onRetry: cases.loadFailed ? cases.load : exams.load,
            )
          else if (!cases.isLoaded || !exams.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (witness == null)
            const Text(
              'This witness is not part of the active case. Return to Case to choose a witness.',
            )
          else ...[
            Text(witness.name, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: Spacing.sm),
            Text('${witness.description} · ${witness.side.label} witness'),
            const SizedBox(height: Spacing.md),
            GavelSegmentedControl<TrialPhase>(
              selected: widget.phase,
              options: const {
                TrialPhase.direct: 'Direct',
                TrialPhase.cross: 'Cross',
              },
              keyFor: (phase) => ValueKey('exam_phase_${phase.name}'),
              onChanged: (phase) => context.replace(
                Routes.exam(widget.witnessId, phase: phase.name),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              '${exams.sideFor(widget.witnessId, widget.phase).label} ${widget.phase.label.toLowerCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.xxl,
              runSpacing: Spacing.md,
              children: [
                StatTile(
                  value: '${script!.questions.length}',
                  label: 'Drafted',
                ),
                StatTile(
                  value:
                      '${script.questions.where((q) => q.exhibitIds.isNotEmpty || q.sourceIds.isNotEmpty).length}',
                  label: 'Evidence-linked',
                ),
                StatTile(
                  value: '${script.questions.where((q) => q.flagged).length}',
                  label: 'Flagged',
                ),
              ],
            ),
            Wrap(
              spacing: Spacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (exams.isSaving || script.questions.isEmpty)
                  Text(script.status.label)
                else
                  PopupMenuButton<ExamStatus>(
                    key: const ValueKey('exam_review_status'),
                    tooltip: 'Change script review status',
                    initialValue: script.status,
                    onSelected: (status) =>
                        exams.save(script.copyWith(status: status)),
                    itemBuilder: (_) => [
                      for (final status in ExamStatus.values)
                        PopupMenuItem(value: status, child: Text(status.label)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      child: Text('${script.status.label} ▾'),
                    ),
                  ),
                if (script.questions.isNotEmpty &&
                    team.teammates.isNotEmpty &&
                    !exams.isSaving)
                  PopupMenuButton<String>(
                    key: const ValueKey('exam_reviewer'),
                    tooltip: 'Choose reviewer',
                    initialValue: script.reviewerId ?? '',
                    onSelected: (id) => exams.save(
                      script.copyWith(
                        reviewerId: id,
                        clearReviewer: id.isEmpty,
                      ),
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: '',
                        child: Text('No reviewer'),
                      ),
                      for (final teammate in team.teammates)
                        PopupMenuItem(
                          value: teammate.id,
                          child: Text(teammate.name),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      child: Text(
                        'Reviewer: ${team.byId(script.reviewerId ?? '')?.name ?? 'Choose'}',
                      ),
                    ),
                  ),
                if (cases.affidavits
                        .where((item) => item.witnessId == witness.id)
                        .firstOrNull
                    case final affidavit?)
                  TextButton(
                    key: const ValueKey('exam_open_affidavit'),
                    onPressed: () =>
                        context.push(Routes.affidavit(affidavit.id)),
                    child: const Text('Read affidavit'),
                  ),
              ],
            ),
            WorkspaceColumns(
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Examination goal'),
                  Text(
                    script.goal.isEmpty
                        ? 'Set a focused goal for this witness’s examination.'
                        : script.goal,
                    key: const ValueKey('exam_goal'),
                  ),
                  TextButton(
                    key: const ValueKey('exam_edit_goal'),
                    onPressed: exams.isSaving
                        ? null
                        : () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            isDismissible: false,
                            enableDrag: false,
                            builder: (_) => GoalEditorSheet(
                              initial: script.goal,
                              onSave: (goal) => exams.save(
                                exams
                                    .scriptFor(witness.id, widget.phase)
                                    .copyWith(goal: goal),
                              ),
                            ),
                          ),
                    child: const Text('Edit goal'),
                  ),
                  const SectionHeader(title: 'Question line'),
                  Wrap(
                    spacing: Spacing.md,
                    runSpacing: Spacing.sm,
                    children: [
                      FilledButton(
                        key: const ValueKey('exam_add_question'),
                        onPressed: exams.isSaving
                            ? null
                            : () => _editor(exams, cases),
                        child: const Text('Add question'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('exam_suggest'),
                        onPressed: exams.isSaving || exams.isSuggesting
                            ? null
                            : () => exams.suggest(witness.id, widget.phase),
                        child: Text(
                          exams.isSuggesting
                              ? 'Preparing suggestions…'
                              : 'Suggest with AI',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'Demo suggestions are prepared prompts, not live AI. Review them against the affidavit before use.',
                  ),
                  if (exams.suggestFailedFor(witness.id, widget.phase))
                    const Text(
                      'Suggestions unavailable. Use Suggest with AI to retry.',
                      key: ValueKey('exam_suggest_error'),
                    ),
                  for (final (index, text)
                      in exams.suggestionsFor(witness.id, widget.phase).indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text),
                          TextButton(
                            key: ValueKey('exam_use_suggestion_$index'),
                            onPressed:
                                exams.isSaving ||
                                    script.questions.any((q) => q.text == text)
                                ? null
                                : () => exams.upsertQuestion(
                                    witness.id,
                                    widget.phase,
                                    ExamQuestion(
                                      id: exams.newQuestionId(),
                                      text: text,
                                      flagged: true,
                                    ),
                                  ),
                            child: Text(
                              script.questions.any((q) => q.text == text)
                                  ? 'Added'
                                  : 'Add for review',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (exams.saveFailedFor(witness.id, widget.phase))
                    const Text(
                      'Could not save this change. Your saved script is unchanged; try the action again.',
                      key: ValueKey('exam_save_error'),
                    ),
                  const SizedBox(height: Spacing.lg),
                  if (script.questions.isEmpty)
                    const Text(
                      'No questions yet. Add your first question or review a demo suggestion.',
                    ),
                  if (requested != null &&
                      !script.questions.any((q) => q.id == requested))
                    const Text(
                      'The linked question is no longer in this script.',
                    ),
                  for (final (index, question) in script.questions.indexed)
                    QuestionTile(
                      key: _anchors.putIfAbsent(question.id, () => GlobalKey()),
                      question: question,
                      number: index + 1,
                      exhibitById: cases.exhibitById,
                      highlighted: question.id == requested,
                      sourceLabel: (id) => research.sourceById(id)?.title ?? id,
                      onExhibit: (id) =>
                          context.push(Routes.researchSource(id)),
                      onResearch: () {
                        final phase = widget.phase;
                        context.push(
                          Routes.research,
                          extra: ResearchContext(
                            label: 'question ${index + 1}',
                            excerpt: question.text,
                            attachSource: (id) => exams.attachSource(
                              witness.id,
                              phase,
                              question.id,
                              id,
                            ),
                          ),
                        );
                      },
                      onEdit: exams.isSaving
                          ? null
                          : () => _editor(exams, cases, question),
                      onUp: exams.isSaving || index == 0
                          ? null
                          : () => exams.moveQuestion(
                              witness.id,
                              widget.phase,
                              index,
                              -1,
                            ),
                      onDown:
                          exams.isSaving || index == script.questions.length - 1
                          ? null
                          : () => exams.moveQuestion(
                              witness.id,
                              widget.phase,
                              index,
                              1,
                            ),
                      onDelete: exams.isSaving
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete question?'),
                                  content: const Text(
                                    'This removes the question and its exhibit citations from the script.',
                                  ),
                                  actions: [
                                    TextButton(
                                      key: const ValueKey('exam_delete_cancel'),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      key: const ValueKey(
                                        'exam_delete_confirm',
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                await exams.deleteQuestion(
                                  witness.id,
                                  widget.phase,
                                  question.id,
                                );
                              }
                            },
                    ),
                ],
              ),
              secondary: Padding(
                padding: const EdgeInsets.only(top: Spacing.lg),
                child: ExamTimingCard(
                  scriptSeconds: script.estimatedSeconds,
                  totalSeconds: exams.budgetSeconds(witness.id, widget.phase),
                  rule: exams.ruleFor(widget.phase),
                  side: exams.sideFor(witness.id, widget.phase).label,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            const Text(
              'Drafts are saved in this browser. Exhibit links track preparation references, not admitted evidence.',
            ),
          ],
        ],
      ),
    );
  }
}
