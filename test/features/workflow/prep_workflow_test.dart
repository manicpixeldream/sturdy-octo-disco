import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/features/case_file/affidavit_page.dart';
import 'package:gavel/features/examination/examination_page.dart';
import 'package:gavel/state/exam_controller.dart';
import 'package:gavel/state/research_controller.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../helpers/pump_app.dart';

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder keyed(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets(
    'Home assignment opens the script and Research attaches a source',
    (tester) async {
      await pumpGavelApp(tester);
      await tap(tester, find.byKey(GavelKeys.homeAssignment('task_1')));
      final exam = find.byType(ExaminationPage);
      final controller = tester.element(exam).read<ExamController>();
      final id = controller.newQuestionId();
      expect(
        await controller.upsertQuestion(
          'wit_reyes',
          TrialPhase.direct,
          ExamQuestion(id: id, text: 'What did you see?'),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();

      await tap(tester, keyed('question_research_$id'));
      expect(find.text('Research for question 1'), findsOneWidget);
      await tap(tester, keyed('research_suggestion_0'));
      final research = tester
          .element(keyed('research_back_to_work'))
          .read<ResearchController>();
      await tap(tester, keyed('citation_${research.messages.last.id}_0_ex_4'));
      await tap(tester, keyed('research_attach_to_work'));
      await tap(tester, keyed('source_back'));
      await tap(tester, keyed('research_back_to_work'));

      expect(find.text('What did you see?'), findsOneWidget);
      expect(keyed('exam_link_${id}_ex_4'), findsOneWidget);
      await tap(tester, keyed('exam_review_status'));
      await tap(tester, find.text('Ready for review'));
      expect(
        controller.scriptFor('wit_reyes', TrialPhase.direct).status,
        ExamStatus.review,
      );
    },
  );

  testWidgets('Practice agenda opens a draft and assigns a follow-up', (
    tester,
  ) async {
    await pumpGavelApp(
      tester,
      initialLocation: Routes.schedule,
      clock: Clock.fixed(DateTime(2026, 10, 26, 19)),
    );
    expect(find.text('Past practices'), findsOneWidget);
    await tap(tester, keyed('practice_agenda_practice_0'));
    await tap(tester, keyed('practice_add_agenda_item'));
    await tap(tester, find.text('Opening statement'));
    expect(find.text('1. Opening statement'), findsOneWidget);
    await tap(tester, find.text('Open draft'));
    expect(keyed('argument_opening'), findsOneWidget);
    expect(keyed('argument_closing'), findsNothing);

    final navigator = Navigator.of(tester.element(keyed('argument_opening')));
    navigator.pop();
    await tester.pumpAndSettle();
    await tap(tester, keyed('practice_add_follow_up'));
    await tester.enterText(
      keyed('practice_follow_up_title'),
      'Check opening timing',
    );
    await tap(tester, keyed('practice_follow_up_submit'));
    final tasks = tester
        .element(keyed('practice_add_follow_up'))
        .read<TaskController>();
    expect(
      tasks
          .tasksFor('tm_sofia')
          .any((task) => task.title == 'Check opening timing'),
      isTrue,
    );
  });

  testWidgets('Home opens the dashboard after working in another tab', (
    tester,
  ) async {
    await pumpGavelApp(tester);
    final assignment = find.byKey(GavelKeys.homeAssignment('task_1'));
    await tap(tester, assignment);
    await tap(tester, find.byKey(GavelKeys.navTeam));
    await tap(tester, find.byKey(GavelKeys.navHome));
    expect(assignment, findsOneWidget);
    expect(find.byType(ExaminationPage), findsNothing);
  });

  testWidgets('switching exam phases preserves the affidavit back route', (
    tester,
  ) async {
    await pumpGavelApp(tester, initialLocation: Routes.affidavit('aff_reyes'));
    await tap(tester, keyed('affidavit_exam_direct'));
    await tap(tester, keyed('exam_phase_cross'));
    await tap(tester, keyed('exam_back'));
    expect(find.byType(AffidavitPage), findsOneWidget);
  });

  testWidgets('a saved exam link cannot select a new question after restart', (
    tester,
  ) async {
    await pumpGavelApp(tester, initialLocation: Routes.exam('wit_reyes'));
    final exam = find.byType(ExaminationPage);
    final previous = tester
        .element(exam)
        .read<ExamController>()
        .newQuestionId();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpGavelApp(
      tester,
      initialLocation: Routes.exam('wit_reyes', questionId: previous),
    );
    final controller = tester.element(exam).read<ExamController>();
    final current = controller.newQuestionId();
    expect(current, isNot(previous));
    expect(
      await controller.upsertQuestion(
        'wit_reyes',
        TrialPhase.direct,
        ExamQuestion(id: current, text: 'A different question'),
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('The linked question is no longer in this script.'),
      findsOneWidget,
    );
  });

  testWidgets('Team Chat links to an exact examination script', (tester) async {
    await pumpGavelApp(tester, initialLocation: Routes.teamChat);
    await tap(tester, keyed('chat_link_item'));
    await tap(tester, keyed('mention_kind_draft'));
    final route = Routes.exam('wit_reyes');
    await tap(tester, keyed('mention_pick_draft:$route'));
    await tap(tester, keyed('chat_mentions_apply'));
    await tap(tester, keyed('chat_send'));
    await tap(tester, find.textContaining('Draft · Officer Dana Reyes'));
    final exam = tester.widget<ExaminationPage>(find.byType(ExaminationPage));
    expect(exam.witnessId, 'wit_reyes');
    expect(exam.phase, TrialPhase.direct);
  });

  testWidgets('Research preserves draft when browsing Library', (tester) async {
    await pumpGavelApp(tester, initialLocation: Routes.research);
    await tester.enterText(keyed('research_input'), 'My unsent question');
    await tap(tester, keyed('research_library_mode'));
    await tap(tester, keyed('research_ask_mode'));
    expect(find.text('My unsent question'), findsOneWidget);
  });

  testWidgets('Research fits a short viewport with the keyboard up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await pumpGavelApp(tester, initialLocation: Routes.research);
    expect(tester.takeException(), isNull);
  });
}
