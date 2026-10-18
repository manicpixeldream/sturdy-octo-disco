import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/case_brief.dart';

void main() {
  final today = DateTime(2026, 10, 10);
  final seed = SeedData.harmon(today: today);

  test('State v. Harmon seed keeps the case-packet counts', () {
    expect(seed.caseFile.title, 'State v. Harmon');
    expect(seed.exhibits, hasLength(14));
    expect(seed.witnesses, hasLength(6));
    expect(seed.teammates, hasLength(6));
    expect(seed.tasks, hasLength(12));
    expect(seed.exhibits.map((e) => e.number), [
      for (var i = 1; i <= 14; i++) i,
    ]);
    expect(seed.currentTeammateId, 'tm_sofia');
    expect(
      seed.caseFile.trialDate,
      DateTime(today.year, today.month, today.day + 23),
    );
  });

  test('seed names match the Harmon packet', () {
    expect(
      seed.witnesses.map((w) => w.name),
      containsAll(['Officer Dana Reyes', 'Mara Okafor', 'Casey Harmon']),
    );
    expect(
      seed.teammates.map((t) => t.name),
      containsAll(['Sofia Reyes', 'Marcus Bell']),
    );
  });

  test(
    'v0.5 sample packet has complete witness coverage and valid evidence links',
    () {
      expect(seed.affidavits, hasLength(6));
      expect(
        seed.affidavits.map((a) => a.witnessId).toSet(),
        seed.witnesses.map((w) => w.id).toSet(),
      );
      expect(seed.stipulations, hasLength(3));
      expect(seed.timingRules.map((r) => r.minutes), [5, 25, 20, 9]);
      expect(seed.timingRules.map((r) => r.phase).toSet(), hasLength(4));
      expect(seed.caseBrief.facts, isNotEmpty);
      expect(seed.caseBrief.arguments, isNotEmpty);
      for (final fact in seed.caseBrief.facts) {
        expect(fact.evidence, isNotEmpty);
        for (final link in fact.evidence) {
          final ids = switch (link.kind) {
            EvidenceKind.exhibit => seed.exhibits.map((e) => e.id),
            EvidenceKind.affidavit => seed.affidavits.map((a) => a.id),
          };
          expect(ids, contains(link.sourceId));
          expect(link.note, isNotEmpty);
        }
      }
      for (final recordCaseIds in [
        seed.affidavits.map((a) => a.caseId),
        seed.stipulations.map((s) => s.caseId),
        seed.timingRules.map((r) => r.caseId),
      ]) {
        expect(recordCaseIds.every((id) => id == seed.caseFile.id), isTrue);
      }
    },
  );
}
