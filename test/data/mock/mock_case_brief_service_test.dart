import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_case_brief_service.dart';
import 'package:gavel/data/mock/seed_data.dart';

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  final service = MockCaseBriefService(seed.caseBrief);

  test('returns the supplied brief only for its case', () async {
    expect(await service.fetchBrief(seed.caseFile.id), seed.caseBrief);
    await expectLater(service.fetchBrief('another_case'), throwsStateError);
  });
}
