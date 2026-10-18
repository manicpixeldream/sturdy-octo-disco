import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/seed_data.dart';

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
}
