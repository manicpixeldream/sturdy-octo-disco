import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/storage/workspace_storage.dart';
import 'package:gavel/data/models/citation.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/features/home/home_page.dart';
import 'package:gavel/state/case_controller.dart';
import 'package:gavel/state/chat_controller.dart';
import 'package:gavel/state/exam_controller.dart';
import 'package:gavel/state/research_controller.dart';
import 'package:gavel/state/role_controller.dart';
import 'package:gavel/state/schedule_controller.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'workspace restores saved work and links after rebuilding the app',
    (tester) async {
      final storage = WorkspaceStorage.memory();
      final day = DateTime(2026, 10, 26);
      Future<void> launch(DateTime now) async {
        await tester.pumpWidget(
          GavelApp(clock: Clock.fixed(now), storage: storage),
        );
        await tester.pumpAndSettle();
      }

      T state<T>() => tester.element(find.byType(HomePage)).read<T>();

      await launch(day);
      final cases = state<CaseController>();
      final caseId = cases.activeCase!.id;
      final trial = cases.activeCase!.trialDate;
      const witness = 'wit_reyes';
      const phase = TrialPhase.direct;
      final exam = state<ExamController>();
      final question = ExamQuestion(
        id: exam.newQuestionId(),
        text: 'What did you see?',
      );
      expect(await exam.upsertQuestion(witness, phase, question), isTrue);
      expect(
        await exam.attachSource(witness, phase, question.id, 'aff_okafor'),
        isTrue,
      );
      expect(
        await exam.save(
          exam
              .scriptFor(witness, phase)
              .copyWith(status: ExamStatus.review, reviewerId: 'tm_marcus'),
        ),
        isTrue,
      );
      cases.updateArgumentDraft(
        caseId,
        TrialPhase.opening,
        'Members of the jury',
      );
      expect(
        cases.attachArgumentSource(caseId, TrialPhase.opening, 'ex_4'),
        isTrue,
      );

      final research = state<ResearchController>();
      final answer = research.send('Explain relevance and motive');
      await tester.pump(const Duration(milliseconds: 300));
      await answer;
      final answerId = research.messages.last.id;
      research.toggleSaved('ex_4');
      research.saveDraft('Unsent research question');

      final chat = state<ChatController>();
      expect(await chat.send('Please review the opening.', const []), isTrue);
      chat.saveDraft('Unsent chat', [chat.availableMentions.first]);
      final roles = state<RoleController>();
      expect(await roles.assign('defense_closing', 'tm_marcus'), isTrue);
      final tasks = state<TaskController>();
      expect(await tasks.setCompleted('task_1', true), isTrue);
      tasks.addFollowUp(
        'Time the opening',
        'tm_sofia',
        day,
        workRoute: Routes.practiceAgenda('practice_0'),
      );
      final schedule = state<ScheduleController>();
      schedule.setAgenda(caseId, 'practice_0', [
        (witnessId: witness, phase: phase),
      ]);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await launch(day.add(const Duration(days: 1)));

      final restored = state<ExamController>().scriptFor(witness, phase);
      expect(restored.status, ExamStatus.review);
      expect(restored.reviewerId, 'tm_marcus');
      expect(restored.questions.single.id, question.id);
      expect(restored.questions.single.sourceIds, ['aff_okafor']);
      expect(
        find.text('Ready for review · Reviewer: Marcus Bell'),
        findsOneWidget,
      );

      final restoredCase = state<CaseController>();
      expect(restoredCase.activeCase!.trialDate, trial);
      expect(
        restoredCase.argumentDraft(caseId, TrialPhase.opening),
        'Members of the jury',
      );
      final restoredResearch = state<ResearchController>();
      expect(restoredResearch.messages.last.id, answerId);
      expect(restoredResearch.draft, 'Unsent research question');
      expect(restoredResearch.isSaved('ex_4'), isTrue);
      expect(
        restoredResearch
            .citationsFor('ex_4')
            .any((citation) => citation.location == CitationLocation.argument),
        isTrue,
      );
      restoredCase.detachArgumentSource(caseId, TrialPhase.opening, 'ex_4');
      expect(
        restoredResearch
            .citationsFor('ex_4')
            .any((citation) => citation.location == CitationLocation.argument),
        isFalse,
      );
      expect(
        state<ChatController>().messages.single.text,
        'Please review the opening.',
      );
      expect(state<ChatController>().draftText, 'Unsent chat');
      expect(state<ChatController>().draftMentions, hasLength(1));
      expect(
        state<RoleController>().assignmentFor('defense_closing')?.teammateId,
        'tm_marcus',
      );
      expect(
        state<TaskController>().tasks
            .firstWhere((task) => task.id == 'task_1')
            .isDone,
        isTrue,
      );
      expect(
        state<TaskController>().tasks
            .firstWhere((task) => task.title == 'Time the opening')
            .workRoute,
        Routes.practiceAgenda('practice_0'),
      );
      expect(
        state<ScheduleController>().sessionById('practice_0')?.startsAt.day,
        day.day,
      );
      expect(
        state<ScheduleController>()
            .agenda(caseId, 'practice_0')
            .single
            .witnessId,
        witness,
      );
    },
  );
}
