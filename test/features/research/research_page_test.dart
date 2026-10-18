import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_research_service.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/research_message.dart';
import 'package:gavel/data/models/research_source.dart';
import 'package:gavel/data/services/research_service.dart';
import 'package:gavel/features/research/research_page.dart';
import 'package:gavel/features/research/source_detail_page.dart';
import 'package:gavel/features/case_file/widgets/section_chips.dart';
import 'package:gavel/state/research_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../helpers/pump_app.dart';

class _Service implements ResearchService {
  _Service(this.delegate);
  final MockResearchService delegate;
  bool failSources = false;
  bool failReply = false;
  Completer<ResearchReply>? pending;
  @override
  Future<List<ResearchSource>> fetchSources(String id) async {
    if (failSources) throw StateError('offline');
    return delegate.fetchSources(id);
  }

  @override
  Future<ResearchReply> ask({
    required String caseId,
    required String question,
    required List<ResearchMessage> history,
  }) async {
    if (failReply) throw StateError('offline');
    if (pending case final value?) return value.future;
    return delegate.ask(caseId: caseId, question: question, history: history);
  }
}

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  late _Service service;
  setUp(() {
    service = _Service(
      MockResearchService(
        caseRepository: MockCaseRepository(
          activeCase: seed.caseFile,
          exhibits: seed.exhibits,
          witnesses: seed.witnesses,
          affidavits: seed.affidavits,
        ),
        delay: Duration.zero,
      ),
    );
  });
  ResearchController state(WidgetTester tester) =>
      tester.element(find.byType(ResearchPage)).read<ResearchController>();
  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('research_input')), text);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('research_send')));
    await tester.pumpAndSettle();
  }

  Future<void> launch(WidgetTester tester) => pumpGavelApp(
    tester,
    initialLocation: Routes.research,
    seed: seed,
    researchService: service,
  );

  testWidgets(
    'question, pending state, sourced reply, and suggestion controls work',
    (tester) async {
      service.pending = Completer<ResearchReply>();
      await launch(tester);
      expect(find.textContaining('No live AI'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('research_suggestion_0')));
      await tester.pump();
      expect(find.text('Build the case timeline'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('research_reply_loading')),
        findsOneWidget,
      );
      expect(state(tester).messages, hasLength(1));
      service.pending!.complete(
        await service.delegate.ask(
          caseId: seed.caseFile.id,
          question: 'timeline',
          history: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Build the timeline from the packet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('citation_message_2_0_ex_4')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'citation opens source, save adds Library item, Cited in returns to answer',
    (tester) async {
      await launch(tester);
      await send(tester, 'Explain relevance and motive');
      final chip = find.byKey(
        const ValueKey('citation_message_2_1_source_relevance'),
      );
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.byType(SourceDetailPage), findsOneWidget);
      expect(find.byKey(const ValueKey('source_citation')), findsOneWidget);
      final save = find.byKey(const ValueKey('research_save_source_relevance'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Saved to Library'), findsOneWidget);
      final usage = find.byKey(
        const ValueKey('source_usage_answer:message_2:source_relevance'),
      );
      await tester.ensureVisible(usage);
      await tester.pumpAndSettle();
      await tester.tap(usage);
      await tester.pumpAndSettle();
      expect(find.byType(ResearchPage), findsOneWidget);
      expect(find.text('Connect each inference to its source'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('research_library_mode')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('source_tile_source_relevance')),
        findsOneWidget,
      );
      expect(find.text('Definitions'), findsOneWidget);
    },
  );

  testWidgets(
    'Library groups all categories and handles search, save, and unsave',
    (tester) async {
      await launch(tester);
      await tester.tap(find.byKey(const ValueKey('research_library_mode')));
      await tester.pumpAndSettle();
      expect(find.text('No saved sources yet'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('library_all')));
      await tester.pumpAndSettle();
      for (final label in [
        'Precedents',
        'Definitions',
        'Articles',
        'Case materials',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.enterText(
        find.byKey(const ValueKey('library_search')),
        'Daubert',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('source_tile_source_daubert')),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(const ValueKey('library_save_source_daubert')),
        ),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('library_save_source_daubert')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('library_saved')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('library_saved')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('source_tile_source_daubert')),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(const ValueKey('library_save_source_daubert')),
        ),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('library_save_source_daubert')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('source_tile_source_daubert')),
        findsNothing,
      );
    },
  );

  testWidgets('brief usages open the actual Brief section and fact', (
    tester,
  ) async {
    await pumpGavelApp(
      tester,
      initialLocation: Routes.researchSource('ex_4'),
      seed: seed,
      researchService: service,
    );
    final usage = find.byKey(
      const ValueKey('source_usage_caseBrief:fact_call:ex_4'),
    );
    await tester.ensureVisible(usage);
    await tester.pumpAndSettle();
    await tester.tap(usage);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SectionChips>(find.byType(SectionChips)).selected,
      CaseSection.brief,
    );
    final fact = find.byKey(const ValueKey('case_record_fact_call'));
    expect(fact, findsOneWidget);
    expect(tester.getRect(fact).top, greaterThanOrEqualTo(0));
  });

  testWidgets('catalogue and response errors have working retry paths', (
    tester,
  ) async {
    service.failSources = true;
    await launch(tester);
    expect(find.text('Could not load research sources'), findsOneWidget);
    service.failSources = false;
    await tester.tap(find.byKey(const ValueKey('load_retry')));
    await tester.pumpAndSettle();
    service.failReply = true;
    await send(tester, 'timeline');
    expect(find.byKey(const ValueKey('research_reply_error')), findsOneWidget);
    service.failReply = false;
    final retry = find.byKey(const ValueKey('research_retry_reply'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(state(tester).messages, hasLength(2));
    expect(find.text('Build the timeline from the packet'), findsOneWidget);
  });

  testWidgets(
    'source URLs are independently readable, and missing sources are explicit',
    (tester) async {
      await pumpGavelApp(
        tester,
        initialLocation: Routes.researchSource('source_daubert'),
        seed: seed,
        researchService: service,
      );
      expect(find.textContaining('509 U.S.'), findsOneWidget);
      final page = tester.element(find.byType(SourceDetailPage));
      GoRouter.of(page).go(Routes.researchSource('missing'));
      await tester.pumpAndSettle();
      expect(find.text('Source unavailable'), findsOneWidget);
    },
  );
}
