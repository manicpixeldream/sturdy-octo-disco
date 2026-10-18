import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_research_service.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/research_source.dart';

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  final service = MockResearchService(
    caseRepository: MockCaseRepository(
      activeCase: seed.caseFile,
      exhibits: seed.exhibits,
      witnesses: seed.witnesses,
      affidavits: seed.affidavits,
    ),
    delay: Duration.zero,
  );

  test(
    'catalogue has three source categories and the unchanged case materials',
    () async {
      final sources = await service.fetchSources(seed.caseFile.id);
      expect(sources, hasLength(23));
      expect(sources.map((s) => s.id).toSet(), hasLength(23));
      for (final kind in ResearchSourceKind.values) {
        expect(sources.where((s) => s.kind == kind), isNotEmpty);
      }
      expect(
        sources.singleWhere((s) => s.id == 'aff_okafor').content,
        seed.affidavits[1].body,
      );
      expect(
        sources.singleWhere((s) => s.id == 'ex_4').content,
        seed.exhibits[3].description,
      );
      expect(
        (await service.fetchSources('other')).where((s) => s.caseId != null),
        isEmpty,
      );
    },
  );

  test('prepared topics and fallback cite only existing records', () async {
    final sources = await service.fetchSources(seed.caseFile.id);
    for (final question in [
      'timeline of the fire',
      'eyewitness identification',
      'fire experts',
      'relevance and motive',
      'unknown topic',
    ]) {
      final reply = await service.ask(
        caseId: seed.caseFile.id,
        question: question,
        history: [],
      );
      for (final point in reply.points) {
        expect(point.sourceIds, isNotEmpty);
        expect(
          point.sourceIds.every((id) => sources.any((s) => s.id == id)),
          isTrue,
        );
      }
    }
    final timeline = await service.ask(
      caseId: seed.caseFile.id,
      question: 'timeline of the fire',
      history: [],
    );
    expect(timeline.title, 'Build the timeline from the packet');
    final other = await service.ask(
      caseId: 'other',
      question: 'timeline',
      history: [],
    );
    expect(other.title, 'Start with the available sources');
    expect(
      other.points.expand((p) => p.sourceIds),
      everyElement(startsWith('source_')),
    );
  });
}
