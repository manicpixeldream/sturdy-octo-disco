import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/mock/mock_case_brief_service.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_research_service.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/citation.dart';
import 'package:gavel/data/models/case_file.dart';
import 'package:gavel/data/models/research_message.dart';
import 'package:gavel/data/models/research_source.dart';
import 'package:gavel/data/services/research_service.dart';
import 'package:gavel/state/case_controller.dart';
import 'package:gavel/state/research_controller.dart';

class TestResearchService implements ResearchService {
  TestResearchService({required this.sources, required this.reply});
  List<ResearchSource> sources;
  Future<ResearchReply> Function() reply;
  bool failCatalogue = false;
  @override
  Future<List<ResearchSource>> fetchSources(String id) async {
    if (failCatalogue) throw StateError('offline');
    return sources;
  }

  @override
  Future<ResearchReply> ask({
    required String caseId,
    required String question,
    required List<ResearchMessage> history,
  }) => reply();
}

class _SwitchableCases extends MockCaseRepository {
  _SwitchableCases(SeedData seed)
    : current = seed.caseFile,
      super(
        activeCase: seed.caseFile,
        exhibits: seed.exhibits,
        witnesses: seed.witnesses,
      );
  CaseFile current;
  @override
  Future<CaseFile> fetchActiveCase() async => current;
}

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  late CaseController cases;
  late MockResearchService mock;
  late TestResearchService service;
  late ResearchController research;

  setUp(() async {
    final repository = MockCaseRepository(
      activeCase: seed.caseFile,
      exhibits: seed.exhibits,
      witnesses: seed.witnesses,
      affidavits: seed.affidavits,
      stipulations: seed.stipulations,
      timingRules: seed.timingRules,
    );
    cases = CaseController(
      repository,
      const Clock(),
      briefService: MockCaseBriefService(seed.caseBrief),
    );
    await cases.load();
    mock = MockResearchService(
      caseRepository: repository,
      delay: Duration.zero,
    );
    service = TestResearchService(
      sources: await mock.fetchSources(seed.caseFile.id),
      reply: () =>
          mock.ask(caseId: seed.caseFile.id, question: 'timeline', history: []),
    );
    research = ResearchController(service, cases);
    await research.load();
  });
  tearDown(() {
    research.dispose();
    cases.dispose();
  });

  test(
    'send appends the question, loading state, then a source-linked reply',
    () async {
      final pending = Completer<ResearchReply>();
      service.reply = () => pending.future;
      final request = research.send('  Build the timeline  ');
      expect(research.messages, hasLength(1));
      expect(research.messages.first.text, 'Build the timeline');
      expect(research.messages.first.role, ResearchRole.user);
      expect(research.isSending, isTrue);
      expect(await research.send('duplicate'), isFalse);
      pending.complete(
        await mock.ask(
          caseId: seed.caseFile.id,
          question: 'timeline',
          history: [],
        ),
      );
      expect(await request, isTrue);
      expect(research.messages, hasLength(2));
      expect(research.messages.last.role, ResearchRole.assistant);
      expect(research.isSending, isFalse);
      expect(
        research
            .citationsFor('ex_4')
            .where((c) => c.location == CitationLocation.answer),
        hasLength(1),
      );
    },
  );

  test(
    'failed response retries the same question without duplicating it',
    () async {
      service.reply = () async => throw StateError('offline');
      await research.send('timeline');
      expect(research.replyFailed, isTrue);
      expect(research.messages, hasLength(1));
      service.reply = () =>
          mock.ask(caseId: seed.caseFile.id, question: 'timeline', history: []);
      await research.retryReply();
      expect(research.replyFailed, isFalse);
      expect(research.messages, hasLength(2));
      expect(
        research.messages.where((m) => m.role == ResearchRole.user),
        hasLength(1),
      );
    },
  );

  test(
    'invalid or duplicate source references do not produce an uncited answer',
    () async {
      for (final ids in [
        ['missing'],
        ['ex_4', 'ex_4'],
      ]) {
        service.reply = () async => ResearchReply(
          title: 'Invalid',
          points: [ResearchAnswerPoint(text: 'A claim', sourceIds: ids)],
        );
        await research.send('question');
        expect(research.replyFailed, isTrue);
        expect(
          research.messages.where((m) => m.role == ResearchRole.assistant),
          isEmpty,
        );
        research.dismissFailedReply();
      }
    },
  );

  test(
    'saves and citations are distinct, deduplicated, immutable, and live',
    () async {
      expect(research.savedSources, isEmpty);
      research.toggleSaved('source_daubert');
      expect(research.savedSources.map((s) => s.id), ['source_daubert']);
      expect(research.citationsFor('source_daubert'), isEmpty);
      const citation = Citation(
        sourceId: 'source_daubert',
        location: CitationLocation.examQuestion,
        referenceId: 'q1',
        label: 'Question one',
      );
      research.addCitation(citation);
      research.addCitation(citation);
      research.addCitation(citation.copyWith(label: 'Updated question'));
      expect(research.citationsFor('source_daubert'), hasLength(1));
      expect(
        research.citationsFor('source_daubert').single.label,
        'Updated question',
      );
      expect(() => research.messages.clear(), throwsUnsupportedError);
      expect(() => research.sources.clear(), throwsUnsupportedError);
      expect(() => research.toggleSaved('not_a_source'), throwsArgumentError);
      research.toggleSaved('source_daubert');
      expect(research.savedSources, isEmpty);
      expect(research.citationsFor('source_daubert'), hasLength(1));
    },
  );

  test(
    'Cited in indexes actual brief evidence and survives catalogue reload',
    () async {
      expect(
        research
            .citationsFor('aff_okafor')
            .where((c) => c.location == CitationLocation.caseBrief),
        hasLength(2),
      );
      expect(research.citationsFor('source_daubert'), isEmpty);
      await research.load();
      expect(
        research
            .citationsFor('aff_okafor')
            .where((c) => c.location == CitationLocation.caseBrief),
        hasLength(2),
      );
    },
  );

  test(
    'catalogue failure is retryable and foreign/duplicate IDs are rejected',
    () async {
      service.failCatalogue = true;
      await research.load();
      expect(research.loadFailed, isTrue);
      service.failCatalogue = false;
      await research.load();
      expect(research.loadFailed, isFalse);
      service.sources = [...service.sources, service.sources.first];
      await research.load();
      expect(research.loadFailed, isTrue);
      service.sources = [
        const ResearchSource(
          id: 'foreign',
          title: 'Other case',
          kind: ResearchSourceKind.caseMaterial,
          citation: '',
          content: '',
          context: '',
          caseId: 'case_other',
        ),
      ];
      await research.load();
      expect(research.loadFailed, isTrue);
    },
  );

  test('late reply completion after disposal never notifies', () async {
    final pending = Completer<ResearchReply>();
    service.reply = () => pending.future;
    final request = research.send('timeline');
    research.dispose();
    pending.complete(
      await mock.ask(
        caseId: seed.caseFile.id,
        question: 'timeline',
        history: [],
      ),
    );
    await request;
    // Replace the disposed controller for tearDown.
    research = ResearchController(service, cases);
    await research.load();
  });

  testWidgets('a response timeout leaves one retryable question', (
    tester,
  ) async {
    final pending = Completer<ResearchReply>();
    service.reply = () => pending.future;
    final request = research.send('timeline');
    await tester.pump(const Duration(seconds: 21));
    await request;
    expect(research.replyFailed, isTrue);
    expect(research.messages, hasLength(1));
    pending.complete(
      ResearchReply(
        title: 'Late',
        points: [
          ResearchAnswerPoint(
            text: 'Too late',
            sourceIds: ['source_relevance'],
          ),
        ],
      ),
    );
    await tester.pump();
    expect(research.messages, hasLength(1));
  });

  test('changing the active case clears session state and ignores the old pending reply', () async {
    research.dispose();
    cases.dispose();
    final repository = _SwitchableCases(seed);
    cases = CaseController(repository, const Clock());
    await cases.load();
    final pending = Completer<ResearchReply>();
    service.sources = MockResearchService.referenceSources;
    service.reply = () => pending.future;
    research = ResearchController(service, cases);
    await research.load();
    research.toggleSaved('source_daubert');
    final request = research.send('expert evidence');
    repository.current = seed.caseFile.copyWith(
      id: 'case_other',
      title: 'Another case',
    );
    await cases.load();
    await research.load();
    pending.complete(
      ResearchReply(
        title: 'Old case response',
        points: [
          ResearchAnswerPoint(text: 'Old claim', sourceIds: ['source_daubert']),
        ],
      ),
    );
    await request;
    expect(research.caseId, 'case_other');
    expect(research.messages, isEmpty);
    expect(research.savedSources, isEmpty);
    expect(research.isSending, isFalse);
  });

  test('empty and overlong questions are ignored', () async {
    expect(await research.send('   '), isFalse);
    expect(await research.send('a' * 2001), isFalse);
    expect(research.messages, isEmpty);
  });
}
