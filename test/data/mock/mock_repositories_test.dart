import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/mock/mock_team_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/exhibit.dart';
import 'package:gavel/data/models/witness.dart';

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 10));
  final caseRepo = MockCaseRepository(
    activeCase: seed.caseFile,
    exhibits: seed.exhibits,
    witnesses: seed.witnesses,
    affidavits: seed.affidavits,
    stipulations: seed.stipulations,
    timingRules: seed.timingRules,
  );
  final teamRepo = MockTeamRepository(seed.teammates);
  final taskRepo = MockTaskRepository(seed.tasks);

  test('mock repositories return the seeded records', () async {
    expect(await caseRepo.fetchActiveCase(), seed.caseFile);
    expect(await caseRepo.fetchExhibits(seed.caseFile.id), seed.exhibits);
    expect(await caseRepo.fetchWitnesses(seed.caseFile.id), seed.witnesses);
    expect(await caseRepo.fetchAffidavits(seed.caseFile.id), seed.affidavits);
    expect(
      await caseRepo.fetchStipulations(seed.caseFile.id),
      seed.stipulations,
    );
    expect(await caseRepo.fetchTimingRules(seed.caseFile.id), seed.timingRules);
    expect(await teamRepo.fetchTeammates(), seed.teammates);
    expect(await taskRepo.fetchTasks(), seed.tasks);
  });

  test('case repository filters exhibits and witnesses by case id', () async {
    expect(await caseRepo.fetchExhibits('other'), isEmpty);
    expect(await caseRepo.fetchWitnesses('other'), isEmpty);
    expect(await caseRepo.fetchAffidavits('other'), isEmpty);
    expect(await caseRepo.fetchStipulations('other'), isEmpty);
    expect(await caseRepo.fetchTimingRules('other'), isEmpty);
    expect(
      await caseRepo.fetchExhibits(seed.caseFile.id),
      isA<List<Exhibit>>(),
    );
    expect(
      await caseRepo.fetchWitnesses(seed.caseFile.id),
      isA<List<Witness>>(),
    );
  });
}
