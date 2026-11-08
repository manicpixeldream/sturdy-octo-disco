import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_exam_suggestion_service.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/timing_rule.dart';

void main() {
  test('prepared direct and cross prompts are distinct and do not mutate packet data', () async {
    final seed = SeedData.harmon(today: DateTime(2026));
    final service = MockExamSuggestionService();
    final witness = seed.witnesses.first;
    final direct = await service.suggest(witness, TrialPhase.direct);
    final cross = await service.suggest(witness, TrialPhase.cross);
    expect(direct.length, 3);
    expect(cross.length, 3);
    expect(direct, isNot(cross));
    expect(seed.witnesses.first, witness);
  });
}
