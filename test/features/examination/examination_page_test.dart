import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/data/mock/mock_exam_repository.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/data/models/citation.dart';
import 'package:gavel/features/examination/examination_page.dart';
import 'package:gavel/state/exam_controller.dart';
import 'package:gavel/state/research_controller.dart';
import 'package:gavel/state/theme_controller.dart';
import 'package:gavel/core/theme/gavel_theme.dart';

import '../../helpers/pump_app.dart';

class FailingSaveRepository extends MockExamRepository {
  bool fail = true;
  @override
  Future<void> saveScript(ExamScript script) async {
    if (fail) throw StateError('offline');
    return super.saveScript(script);
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(
      find
          .ancestor(
            of: target,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> click(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  final clock = Clock.fixed(DateTime(2026, 10, 26));
  testWidgets('saves Unicode goals and questions within the visible limits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpGavelApp(tester, initialLocation: Routes.exam('wit_reyes'));
    final exams = tester
        .element(find.byType(ExaminationPage))
        .read<ExamController>();
    final goal = '🙂' * 300;
    final question = '🙂' * 1100;
    await click(tester, 'exam_edit_goal');
    await tester.enterText(find.byKey(const ValueKey('exam_goal_text')), goal);
    await click(tester, 'exam_goal_save');
    await click(tester, 'exam_add_question');
    await tester.enterText(
      find.byKey(const ValueKey('question_text')),
      question,
    );
    await click(tester, 'question_save');
    final script = exams.scriptFor('wit_reyes', TrialPhase.direct);
    expect(script.goal, goal);
    expect(script.questions.single.text, question);
  });

  testWidgets(
    'goal, question validation, create, edit, reorder, delete and citations',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpGavelApp(
        tester,
        initialLocation: Routes.exam('wit_reyes'),
        clock: clock,
      );
      final exams = tester
          .element(find.byType(ExaminationPage))
          .read<ExamController>();
      final research = tester
          .element(find.byType(ExaminationPage))
          .read<ResearchController>();
      await click(tester, 'exam_edit_goal');
      await tester.enterText(
        find.byKey(const ValueKey('exam_goal_text')),
        'Establish the scene',
      );
      await click(tester, 'exam_goal_save');
      expect(
        exams.scriptFor('wit_reyes', TrialPhase.direct).goal,
        'Establish the scene',
      );
      await click(tester, 'exam_add_question');
      await click(tester, 'question_save');
      expect(find.text('Enter a question.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('question_text')),
        'Describe the scene.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('question_seconds')),
        '60',
      );
      await click(tester, 'question_exhibit_ex_1');
      await click(tester, 'question_save');
      final first = exams
          .scriptFor('wit_reyes', TrialPhase.direct)
          .questions
          .single;
      expect(first.exhibitIds, ['ex_1']);
      expect(
        research
            .citationsFor('ex_1')
            .where((c) => c.location == CitationLocation.examQuestion)
            .length,
        1,
      );
      await click(tester, 'question_edit_${first.id}');
      await tester.enterText(
        find.byKey(const ValueKey('question_text')),
        'Describe your observations.',
      );
      await click(tester, 'question_exhibit_ex_1');
      await click(tester, 'question_exhibit_ex_2');
      await click(tester, 'question_save');
      expect(
        research
            .citationsFor('ex_1')
            .where((c) => c.location == CitationLocation.examQuestion),
        isEmpty,
      );
      expect(find.text('Describe your observations.'), findsOneWidget);
      await click(tester, 'exam_add_question');
      await tester.enterText(
        find.byKey(const ValueKey('question_text')),
        'What happened next?',
      );
      await click(tester, 'question_save');
      final second = exams
          .scriptFor('wit_reyes', TrialPhase.direct)
          .questions
          .last;
      await click(tester, 'question_up_${second.id}');
      expect(
        exams.scriptFor('wit_reyes', TrialPhase.direct).questions.first.id,
        second.id,
      );
      await click(tester, 'question_delete_${first.id}');
      await click(tester, 'exam_delete_confirm');
      expect(
        exams.scriptFor('wit_reyes', TrialPhase.direct).questions.length,
        1,
      );
      expect(
        research
            .citationsFor('ex_2')
            .where((c) => c.location == CitationLocation.examQuestion),
        isEmpty,
      );
    },
  );
  testWidgets('failed question save keeps the editor draft and can retry', (
    tester,
  ) async {
    final repo = FailingSaveRepository();
    await pumpGavelApp(
      tester,
      initialLocation: Routes.exam('wit_reyes'),
      clock: clock,
      examRepository: repo,
    );
    await click(tester, 'exam_add_question');
    await tester.enterText(
      find.byKey(const ValueKey('question_text')),
      'Keep this draft',
    );
    await click(tester, 'question_save');
    expect(find.byKey(const ValueKey('question_save_error')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('question_text')))
          .controller!
          .text,
      'Keep this draft',
    );
    expect(await repo.fetchScripts('case_harmon'), isEmpty);
    repo.fail = false;
    await click(tester, 'question_save');
    expect(
      (await repo.fetchScripts('case_harmon')).single.questions.single.text,
      'Keep this draft',
    );
    expect(find.byKey(const ValueKey('question_save_error')), findsNothing);
  });
  testWidgets(
    'demo suggestions are opt-in and flagged; direct and cross stay separate',
    (tester) async {
      await pumpGavelApp(
        tester,
        initialLocation: Routes.exam('wit_reyes'),
        clock: clock,
      );
      final exams = tester
          .element(find.byType(ExaminationPage))
          .read<ExamController>();
      await click(tester, 'exam_suggest');
      expect(
        exams.scriptFor('wit_reyes', TrialPhase.direct).questions,
        isEmpty,
      );
      await click(tester, 'exam_use_suggestion_0');
      expect(
        exams
            .scriptFor('wit_reyes', TrialPhase.direct)
            .questions
            .single
            .flagged,
        isTrue,
      );
      await click(tester, 'exam_phase_cross');
      expect(exams.scriptFor('wit_reyes', TrialPhase.cross).questions, isEmpty);
      expect(find.text('Defense cross examination'), findsOneWidget);
    },
  );
  testWidgets('source usage backlink opens the exact question', (tester) async {
    final repo = MockExamRepository([
      ExamScript(
        caseId: 'case_harmon',
        witnessId: 'wit_reyes',
        phase: TrialPhase.cross,
        questions: [
          ExamQuestion(
            id: 'linked',
            text: 'What did you observe?',
            exhibitIds: ['ex_1'],
          ),
        ],
      ),
    ]);
    await pumpGavelApp(
      tester,
      initialLocation: Routes.researchSource('ex_1'),
      clock: clock,
      examRepository: repo,
    );
    await click(
      tester,
      'source_usage_examQuestion:wit_reyes|cross|linked:ex_1',
    );
    expect(find.text('What did you observe?'), findsOneWidget);
    final router = GoRouter.of(tester.element(find.byType(ExaminationPage)));
    expect(router.state.uri.queryParameters['question'], 'linked');
    expect(router.state.uri.queryParameters['phase'], 'cross');
  });
  testWidgets('witness reader opens direct and cross builders', (tester) async {
    await pumpGavelApp(
      tester,
      initialLocation: Routes.affidavit('aff_reyes'),
      clock: clock,
    );
    await click(tester, 'affidavit_exam_direct');
    expect(find.byType(ExaminationPage), findsOneWidget);
  });
  testWidgets(
    'shared over-budget warning includes individually valid scripts',
    (tester) async {
      final repo = MockExamRepository([
        for (final witness in ['wit_reyes', 'wit_okafor'])
          ExamScript(
            caseId: 'case_harmon',
            witnessId: witness,
            phase: TrialPhase.direct,
            questions: [
              ExamQuestion(
                id: witness,
                text: 'Question',
                estimatedSeconds: 800,
              ),
            ],
          ),
      ]);
      await pumpGavelApp(
        tester,
        initialLocation: Routes.exam('wit_reyes'),
        clock: clock,
        examRepository: repo,
      );
      expect(find.byKey(const ValueKey('exam_over_budget')), findsOneWidget);
      expect(find.text('Prosecution: 26m 40s / 25m'), findsOneWidget);
    },
  );
  testWidgets('unknown witness deep link has a way back', (tester) async {
    await pumpGavelApp(
      tester,
      initialLocation: Routes.exam('unknown'),
      clock: clock,
    );
    expect(find.textContaining('This witness is not part'), findsOneWidget);
    await click(tester, 'exam_back');
    expect(find.text('State v. Harmon'), findsOneWidget);
  });
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets(
      'builder, editor and keyboard fit $width across shared themes',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.resetViewInsets);
        await pumpGavelApp(
          tester,
          initialLocation: Routes.exam('wit_reyes'),
          clock: clock,
        );
        final theme = tester
            .element(find.byType(ExaminationPage))
            .read<ThemeController>();
        for (final variant in GavelThemeVariant.values) {
          theme.select(variant);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await click(tester, 'exam_add_question');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('question_text')),
          'Describe your observations.',
        );
        expect(tester.takeException(), isNull);
        await click(tester, 'question_cancel');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
