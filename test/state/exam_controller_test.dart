import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/case_file.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/data/models/trial_side.dart';
import 'package:gavel/data/models/citation.dart';
import 'package:gavel/data/mock/mock_exam_repository.dart';
import 'package:gavel/data/mock/mock_exam_suggestion_service.dart';
import 'package:gavel/data/models/witness.dart';

import '../helpers/exam_fixture.dart';

class FlakyExams extends MockExamRepository {
  bool fail = true;
  bool failLoad = false;
  Completer<void>? pending;
  @override
  Future<List<ExamScript>> fetchScripts(String caseId) async {
    if (failLoad) throw StateError('offline');
    return super.fetchScripts(caseId);
  }

  @override
  Future<void> saveScript(ExamScript script) async {
    await pending?.future;
    if (fail) throw StateError('offline');
    return super.saveScript(script);
  }
}

class FlakySuggestions extends MockExamSuggestionService {
  bool fail = true;
  @override
  Future<List<String>> suggest(Witness witness, TrialPhase phase) async {
    if (fail) throw StateError('offline');
    return super.suggest(witness, phase);
  }
}

class SwitchingCase extends MockCaseRepository {
  SwitchingCase(SeedData seed)
    : current = seed.caseFile,
      super(
        activeCase: seed.caseFile,
        exhibits: seed.exhibits,
        witnesses: seed.witnesses,
        timingRules: seed.timingRules,
      );
  CaseFile current;
  @override
  Future<CaseFile> fetchActiveCase() async => current;
}

void main() {
  test(
    'CRUD, reorder, goal and citation removal stay synchronized across reload',
    () async {
      final f = await ExamFixture.create();
      addTearDown(f.dispose);
      final exams = f.exams;
      final q1 = ExamQuestion(
        id: exams.newQuestionId(),
        text: 'Describe the scene.',
        exhibitIds: ['ex_1'],
        flagged: true,
      );
      final q2 = ExamQuestion(
        id: exams.newQuestionId(),
        text: 'What did you see?',
      );
      expect(
        await exams.upsertQuestion('wit_reyes', TrialPhase.direct, q1),
        isTrue,
      );
      await exams.upsertQuestion('wit_reyes', TrialPhase.direct, q2);
      expect(
        f.research
            .citationsFor('ex_1')
            .where((c) => c.location == CitationLocation.examQuestion)
            .single
            .label,
        contains(q1.text),
      );
      await exams.moveQuestion('wit_reyes', TrialPhase.direct, 1, -1);
      expect(
        exams
            .scriptFor('wit_reyes', TrialPhase.direct)
            .questions
            .map((q) => q.id),
        [q2.id, q1.id],
      );
      await exams.upsertQuestion(
        'wit_reyes',
        TrialPhase.direct,
        q1.copyWith(text: 'Revised question', exhibitIds: ['ex_2']),
      );
      expect(
        f.research
            .citationsFor('ex_1')
            .where((c) => c.location == CitationLocation.examQuestion),
        isEmpty,
      );
      expect(
        f.research
            .citationsFor('ex_2')
            .where((c) => c.location == CitationLocation.examQuestion)
            .single
            .label,
        contains('Revised'),
      );
      await exams.save(
        exams
            .scriptFor('wit_reyes', TrialPhase.direct)
            .copyWith(goal: 'Establish observations'),
      );
      await exams.load();
      await f.research.load();
      expect(
        exams.scriptFor('wit_reyes', TrialPhase.direct).goal,
        'Establish observations',
      );
      expect(
        f.research
            .citationsFor('ex_2')
            .where((c) => c.location == CitationLocation.examQuestion)
            .length,
        1,
      );
      await exams.deleteQuestion('wit_reyes', TrialPhase.direct, q1.id);
      expect(
        f.research
            .citationsFor('ex_2')
            .where((c) => c.location == CitationLocation.examQuestion),
        isEmpty,
      );
      expect(
        await exams.moveQuestion('wit_reyes', TrialPhase.direct, 0, -1),
        isFalse,
      );
      expect(
        await exams.upsertQuestion(
          'wit_reyes',
          TrialPhase.direct,
          q2.copyWith(exhibitIds: ['unknown']),
        ),
        isFalse,
      );
    },
  );
  test(
    'budgets aggregate by examining side and phase, not per witness',
    () async {
      final f = await ExamFixture.create();
      addTearDown(f.dispose);
      final e = f.exams;
      for (final (id, witness) in [('a', 'wit_reyes'), ('b', 'wit_okafor')]) {
        await e.upsertQuestion(
          witness,
          TrialPhase.direct,
          ExamQuestion(id: id, text: 'Question', estimatedSeconds: 800),
        );
      }
      expect(
        e.scriptFor('wit_reyes', TrialPhase.direct).estimatedSeconds,
        lessThan(1500),
      );
      expect(
        e.scriptFor('wit_okafor', TrialPhase.direct).estimatedSeconds,
        lessThan(1500),
      );
      expect(e.budgetSeconds('wit_reyes', TrialPhase.direct), 1600);
      expect(e.overBudget('wit_reyes', TrialPhase.direct), isTrue);
      expect(e.budgetSeconds('wit_harmon', TrialPhase.direct), 0);
      await e.upsertQuestion(
        'wit_harmon',
        TrialPhase.cross,
        ExamQuestion(id: 'c', text: 'Cross', estimatedSeconds: 700),
      );
      await e.upsertQuestion(
        'wit_menon',
        TrialPhase.cross,
        ExamQuestion(id: 'd', text: 'Cross', estimatedSeconds: 700),
      );
      expect(e.sideFor('wit_harmon', TrialPhase.cross), TrialSide.prosecution);
      expect(e.budgetSeconds('wit_harmon', TrialPhase.cross), 1400);
      expect(e.overBudget('wit_harmon', TrialPhase.cross), isTrue);
      expect(e.budgetSeconds('wit_reyes', TrialPhase.direct), 1600);
      expect(e.budgetSeconds('wit_reyes', TrialPhase.cross), 0);
    },
  );
  test('failed saves preserve script and citations, retry succeeds; pending saves cannot race', () async {
    final repo = FlakyExams();
    final f = await ExamFixture.create(repository: repo);
    addTearDown(f.dispose);
    final q = ExamQuestion(id: 'q', text: 'Question', exhibitIds: ['ex_1']);
    expect(
      await f.exams.upsertQuestion('wit_reyes', TrialPhase.direct, q),
      isFalse,
    );
    expect(f.exams.saveFailed, isTrue);
    expect(f.exams.saveFailedFor('wit_reyes', TrialPhase.direct), isTrue);
    expect(f.exams.saveFailedFor('wit_reyes', TrialPhase.cross), isFalse);
    expect(f.exams.scripts, isEmpty);
    expect(
      f.research
          .citationsFor('ex_1')
          .where((c) => c.location == CitationLocation.examQuestion),
      isEmpty,
    );
    repo.fail = false;
    repo.pending = Completer<void>();
    final save = f.exams.upsertQuestion('wit_reyes', TrialPhase.direct, q);
    expect(
      await f.exams.upsertQuestion(
        'wit_reyes',
        TrialPhase.direct,
        q.copyWith(text: 'Second'),
      ),
      isFalse,
    );
    repo.pending!.complete();
    expect(await save, isTrue);
    expect(f.exams.saveFailed, isFalse);
  });
  test('repository and suggestion failures recover independently', () async {
    final repo = FlakyExams()..failLoad = true;
    final suggestions = FlakySuggestions();
    final f = await ExamFixture.create(
      repository: repo,
      suggestions: suggestions,
    );
    addTearDown(f.dispose);
    expect(f.exams.loadFailed, isTrue);
    repo.failLoad = false;
    await f.exams.load();
    expect(f.exams.isLoaded, isTrue);
    await f.exams.suggest('wit_reyes', TrialPhase.direct);
    expect(f.exams.suggestFailed, isTrue);
    suggestions.fail = false;
    await f.exams.suggest('wit_reyes', TrialPhase.direct);
    expect(f.exams.suggestFailed, isFalse);
    expect(f.exams.suggestionsFor('wit_reyes', TrialPhase.direct), isNotEmpty);
    expect(f.exams.suggestionsFor('wit_reyes', TrialPhase.cross), isEmpty);
    expect(f.exams.scripts, isEmpty);
  });
  test(
    'disposed save completion does not index a citation or notify',
    () async {
      final repo = FlakyExams()
        ..fail = false
        ..pending = Completer<void>();
      final f = await ExamFixture.create(repository: repo);
      final save = f.exams.upsertQuestion(
        'wit_reyes',
        TrialPhase.direct,
        ExamQuestion(id: 'q', text: 'Question', exhibitIds: ['ex_1']),
      );
      f.exams.dispose();
      repo.pending!.complete();
      expect(await save, isFalse);
      expect(
        f.research
            .citationsFor('ex_1')
            .where((c) => c.location == CitationLocation.examQuestion),
        isEmpty,
      );
      f.research.dispose();
      f.cases.dispose();
    },
  );
  test(
    'late save from an old case cannot replace the active case state',
    () async {
      final seed = SeedData.harmon(today: DateTime(2026, 10, 26));
      final cases = SwitchingCase(seed);
      final repo = FlakyExams()
        ..fail = false
        ..pending = Completer<void>();
      final f = await ExamFixture.create(
        repository: repo,
        caseRepository: cases,
      );
      addTearDown(f.dispose);
      final pending = f.exams.upsertQuestion(
        'wit_reyes',
        TrialPhase.direct,
        ExamQuestion(id: 'q', text: 'Question', exhibitIds: ['ex_1']),
      );
      cases.current = seed.caseFile.copyWith(id: 'another_case');
      await f.cases.load();
      await f.research.load();
      await f.exams.load();
      repo.pending!.complete();
      expect(await pending, isFalse);
      expect(f.exams.scripts, isEmpty);
      expect(f.exams.isSaving, isFalse);
    },
  );
  test(
    'invalid loaded scripts are rejected before replacing the catalogue',
    () async {
      final repo = MockExamRepository([
        ExamScript(
          caseId: 'case_harmon',
          witnessId: 'unknown',
          phase: TrialPhase.direct,
        ),
      ]);
      final f = await ExamFixture.create(repository: repo);
      addTearDown(f.dispose);
      expect(f.exams.loadFailed, isTrue);
      expect(f.exams.isLoaded, isFalse);
      expect(f.exams.scripts, isEmpty);
    },
  );

  test('missing timing rules do not invent a limit', () async {
    final seed = SeedData.harmon(today: DateTime(2026, 10, 26));
    final cases = MockCaseRepository(
      activeCase: seed.caseFile,
      exhibits: seed.exhibits,
      witnesses: seed.witnesses,
    );
    final f = await ExamFixture.create(caseRepository: cases);
    addTearDown(f.dispose);
    await f.exams.upsertQuestion(
      'wit_reyes',
      TrialPhase.direct,
      ExamQuestion(id: 'q', text: 'Question', estimatedSeconds: 3600),
    );
    expect(f.exams.ruleFor(TrialPhase.direct), isNull);
    expect(f.exams.overBudget('wit_reyes', TrialPhase.direct), isFalse);
  });
}
