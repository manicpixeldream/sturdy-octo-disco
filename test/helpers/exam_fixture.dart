import 'package:gavel/data/repositories/case_repository.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_research_service.dart';
import 'package:gavel/data/mock/mock_exam_repository.dart';
import 'package:gavel/data/mock/mock_exam_suggestion_service.dart';
import 'package:gavel/data/repositories/exam_repository.dart';
import 'package:gavel/data/services/exam_suggestion_service.dart';
import 'package:gavel/state/case_controller.dart';
import 'package:gavel/state/research_controller.dart';
import 'package:gavel/state/exam_controller.dart';

class ExamFixture {
  ExamFixture._(this.cases, this.research, this.exams);
  final CaseController cases;
  final ResearchController research;
  final ExamController exams;
  static Future<ExamFixture> create({
    ExamRepository? repository,
    ExamSuggestionService? suggestions,
    CaseRepository? caseRepository,
  }) async {
    final seed = SeedData.harmon(today: DateTime(2026, 10, 26));
    final repo =
        caseRepository ??
        MockCaseRepository(
          activeCase: seed.caseFile,
          exhibits: seed.exhibits,
          witnesses: seed.witnesses,
          affidavits: seed.affidavits,
          timingRules: seed.timingRules,
        );
    final cases = CaseController(repo, Clock.fixed(DateTime(2026, 10, 26)));
    await cases.load();
    final research = ResearchController(
      MockResearchService(caseRepository: repo),
      cases,
    );
    await research.load();
    final exams = ExamController(
      repository ?? MockExamRepository(),
      suggestions ?? MockExamSuggestionService(),
      cases,
      research,
    );
    await exams.load();
    return ExamFixture._(cases, research, exams);
  }

  void dispose() {
    exams.dispose();
    research.dispose();
    cases.dispose();
  }
}
