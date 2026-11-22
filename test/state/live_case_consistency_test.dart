import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_exam_repository.dart';
import 'package:gavel/data/mock/mock_exam_suggestion_service.dart';
import 'package:gavel/data/mock/mock_research_service.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/case_brief.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/exhibit.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/data/repositories/case_repository.dart';
import 'package:gavel/data/services/case_brief_service.dart';
import 'package:gavel/state/case_controller.dart';
import 'package:gavel/state/exam_controller.dart';
import 'package:gavel/state/research_controller.dart';

class _LiveCase extends MockCaseRepository
    implements LiveCaseRepository, LiveCaseBriefService {
  _LiveCase(SeedData seed)
    : materials = seed.exhibits,
      super(
        activeCase: seed.caseFile,
        exhibits: seed.exhibits,
        witnesses: seed.witnesses,
        affidavits: seed.affidavits,
      );

  List<Exhibit> materials;
  final packets = StreamController<CasePacket>.broadcast();
  final briefs = <String, StreamController<CaseBrief?>>{};

  @override
  Stream<CasePacket> watchCase() => packets.stream;

  @override
  Stream<CaseBrief?> watchBrief(String caseId) =>
      briefs.putIfAbsent(caseId, StreamController<CaseBrief?>.broadcast).stream;

  @override
  Future<CaseBrief> fetchBrief(String caseId) => throw UnimplementedError();

  @override
  Future<List<Exhibit>> fetchExhibits(String caseId) async =>
      materials.where((item) => item.caseId == caseId).toList();
}

void main() {
  test(
    'live packet changes refresh Research and preserve existing exam drafts',
    () async {
      final today = DateTime(2026, 11, 21);
      final seed = SeedData.harmon(today: today);
      final repository = _LiveCase(seed);
      final cases = CaseController(
        repository,
        Clock.fixed(today),
        briefService: repository,
      );
      final service = MockResearchService(
        caseRepository: repository,
        samplePacket: false,
        delay: Duration.zero,
      );
      final research = ResearchController(service, cases);
      final initialQuestion = ExamQuestion(
        id: 'q1',
        text: 'What did you see?',
        exhibitIds: ['ex_1'],
      );
      final exams = ExamController(
        MockExamRepository([
          ExamScript(
            caseId: seed.caseFile.id,
            witnessId: seed.witnesses.first.id,
            phase: TrialPhase.direct,
            questions: [initialQuestion],
          ),
        ]),
        MockExamSuggestionService(),
        cases,
        research,
      );
      addTearDown(() async {
        exams.dispose();
        research.dispose();
        cases.dispose();
        await repository.packets.close();
        for (final stream in repository.briefs.values) {
          await stream.close();
        }
      });

      void publishPacket() => repository.packets.add((
        seed.caseFile,
        (
          repository.materials,
          seed.witnesses,
          seed.affidavits,
          seed.stipulations,
          seed.timingRules,
        ),
      ));
      final load = cases.load();
      publishPacket();
      await load;
      repository.briefs[seed.caseFile.id]!.add(seed.caseBrief);
      await Future<void>.delayed(Duration.zero);
      expect(cases.brief, seed.caseBrief);
      expect(research.sourceById('ex_1')?.title, seed.exhibits.first.title);

      repository.materials = [
        repository.materials.first.copyWith(title: 'Updated exhibit'),
        ...repository.materials.skip(1),
      ];
      publishPacket();
      await Future<void>.delayed(Duration.zero);
      expect(research.sourceById('ex_1')?.title, 'Updated exhibit');
      final response = await service.ask(
        caseId: seed.caseFile.id,
        question: 'timeline',
        history: [],
      );
      expect(response.points.single.sourceIds, ['source_relevance']);

      repository.briefs[seed.caseFile.id]!.add(null);
      repository.materials = repository.materials.skip(1).toList();
      publishPacket();
      await Future<void>.delayed(Duration.zero);
      expect(cases.brief, isNull);
      expect(cases.briefFailed, isFalse);
      expect(research.sourceById('ex_1'), isNull);

      await exams.load();
      expect(exams.loadFailed, isFalse);
      final script = exams.scriptFor(
        seed.witnesses.first.id,
        TrialPhase.direct,
      );
      expect(script.questions, [initialQuestion]);
      expect(await exams.save(script.copyWith(goal: 'Rehearse')), isTrue);
      expect(
        await exams.save(
          script.copyWith(
            questions: [
              initialQuestion.copyWith(exhibitIds: ['ex_1', 'made-up']),
            ],
          ),
        ),
        isFalse,
      );
    },
  );
}
