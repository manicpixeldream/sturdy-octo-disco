import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/features/case_file/affidavit_page.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/case_brief.dart';
import 'package:gavel/data/services/case_brief_service.dart';
import 'package:gavel/features/case_file/widgets/case_brief_section.dart';
import 'package:gavel/features/case_file/widgets/section_chips.dart';
import 'package:gavel/state/theme_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../helpers/pump_app.dart';

class _BriefService implements CaseBriefService {
  _BriefService(this.fetch);
  final Future<CaseBrief> Function(String) fetch;
  @override
  Future<CaseBrief> fetchBrief(String caseId) => fetch(caseId);
}

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));

  Future<void> select(WidgetTester tester, String section) async {
    final scrollable = find
        .descendant(
          of: find.byKey(const PageStorageKey('case_scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    final chip = find.byKey(GavelKeys.caseSection(section));
    if (chip.evaluate().isEmpty) {
      final more = find.byKey(const ValueKey('case_more'));
      await Scrollable.ensureVisible(tester.element(more), alignment: 0.5);
      await tester.tap(more);
      await tester.pumpAndSettle();
    }
    await Scrollable.ensureVisible(tester.element(chip), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  testWidgets('primary tabs and More preserve all six sections and selection', (
    tester,
  ) async {
    await pumpGavelApp(tester, initialLocation: Routes.caseFile, seed: seed);
    expect(find.text('14 exhibits'), findsOneWidget);
    expect(find.text('6 witnesses'), findsOneWidget);
    expect(find.text('6 affidavits'), findsOneWidget);
    expect(find.text(seed.caseFile.summary), findsOneWidget);

    for (final (section, title) in [
      ('brief', 'Key facts & evidence'),
      ('affidavits', 'Affidavits (6)'),
      ('exhibits', 'Exhibits (14)'),
      ('stipulations', 'Stipulations (3)'),
      ('rules', 'Timing rules'),
      ('overview', 'Case overview'),
    ]) {
      await select(tester, section);
      expect(find.text(title), findsOneWidget);
      expect(
        tester.widget<SectionChips>(find.byType(SectionChips)).selected.name,
        section,
      );
      if (section != 'overview') {
        expect(find.text(seed.caseFile.summary), findsNothing);
      }
    }

    await select(tester, 'rules');
    await tester.tap(find.byKey(GavelKeys.navHome));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GavelKeys.navCase));
    await tester.pumpAndSettle();
    expect(find.text('Timing rules'), findsOneWidget);
  });

  testWidgets(
    'each fact link opens its exact exhibit or affidavit and returns to Brief',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: Routes.caseFile, seed: seed);
      await select(tester, 'brief');
      for (final fact in seed.caseBrief.facts) {
        for (final link in fact.evidence) {
          final source = find.byKey(
            GavelKeys.caseEvidence(fact.id, link.sourceId),
          );
          await tester.ensureVisible(source);
          await tester.pumpAndSettle();
          await tester.tap(source);
          await tester.pumpAndSettle();
          final dialog = find.byKey(GavelKeys.caseEvidenceDialog);
          if (link.kind == EvidenceKind.exhibit) {
            expect(dialog, findsOneWidget);
          } else {
            expect(find.byType(AffidavitPage), findsOneWidget);
          }
          final body = switch (link.kind) {
            EvidenceKind.exhibit =>
              seed.exhibits
                  .singleWhere((e) => e.id == link.sourceId)
                  .description,
            EvidenceKind.affidavit =>
              seed.affidavits.singleWhere((a) => a.id == link.sourceId).body,
          };
          expect(find.text(body), findsOneWidget);
          await tester.tap(
            find.byKey(
              link.kind == EvidenceKind.exhibit
                  ? GavelKeys.caseEvidenceClose
                  : const ValueKey('affidavit_back'),
            ),
          );
          await tester.pumpAndSettle();
          expect(dialog, findsNothing);
          expect(find.byType(CaseBriefSection), findsOneWidget);
        }
      }
      for (final argument in seed.caseBrief.arguments) {
        expect(find.text(argument.argument), findsOneWidget);
        expect(find.text(argument.counter), findsOneWidget);
      }
    },
  );

  testWidgets(
    'affidavits, exhibits, and stipulations contain every seeded record',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: Routes.caseFile, seed: seed);
      for (final (section, ids) in [
        ('affidavits', seed.affidavits.map((a) => a.id)),
        ('exhibits', seed.exhibits.map((e) => e.id)),
        ('stipulations', seed.stipulations.map((s) => s.id)),
      ]) {
        await select(tester, section);
        for (final id in ids) {
          expect(find.byKey(GavelKeys.caseRecord(id)), findsOneWidget);
        }
      }
    },
  );

  testWidgets(
    'timing rules distinguish per-side totals from per-witness budgets',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: Routes.caseFile, seed: seed);
      await select(tester, 'rules');
      for (final label in [
        '5 min per side',
        '25 min total per side',
        '20 min total per side',
        '9 min per side',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('counts come from the injected repository, with empty sections', (
    tester,
  ) async {
    await pumpGavelApp(
      tester,
      initialLocation: Routes.caseFile,
      seed: seed,
      caseRepository: MockCaseRepository(
        activeCase: seed.caseFile,
        exhibits: seed.exhibits.take(2).toList(),
        witnesses: const [],
      ),
    );
    expect(find.text('2 exhibits'), findsOneWidget);
    expect(find.text('0 witnesses'), findsOneWidget);
    expect(find.text('0 affidavits'), findsOneWidget);
    for (final (section, message) in [
      ('affidavits', 'No affidavits yet'),
      ('stipulations', 'No stipulations yet'),
      ('rules', 'No timing rules yet'),
    ]) {
      await select(tester, section);
      expect(find.text(message), findsOneWidget);
    }
    await select(tester, 'brief');
    expect(find.text('Source unavailable'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending brief does not block case materials', (tester) async {
    final pending = Completer<CaseBrief>();
    await tester.pumpWidget(
      GavelApp(
        initialLocation: Routes.caseFile,
        seed: seed,
        caseBriefService: _BriefService((_) => pending.future),
      ),
    );
    await tester.pump();
    await tester.pump();
    final chip = find.byKey(GavelKeys.caseSection('brief'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
    expect(find.byKey(const ValueKey('case_brief_loading')), findsOneWidget);
    pending.complete(seed.caseBrief);
    await tester.pumpAndSettle();
    expect(find.text('Key facts & evidence'), findsOneWidget);
  });

  testWidgets('failed brief can retry without losing other sections', (
    tester,
  ) async {
    var calls = 0;
    await pumpGavelApp(
      tester,
      initialLocation: Routes.caseFile,
      seed: seed,
      caseBriefService: _BriefService((_) async {
        if (++calls == 1) throw StateError('offline');
        return seed.caseBrief;
      }),
    );
    await select(tester, 'brief');
    expect(find.text('Could not load the case brief'), findsOneWidget);
    await select(tester, 'exhibits');
    expect(find.text('Exhibits (14)'), findsOneWidget);
    await select(tester, 'brief');
    final retry = find.byKey(GavelKeys.caseBriefRetry);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Key facts & evidence'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('an empty service brief has an honest empty state', (
    tester,
  ) async {
    await pumpGavelApp(
      tester,
      initialLocation: Routes.caseFile,
      seed: seed,
      caseBriefService: _BriefService(
        (id) async => CaseBrief(caseId: id, facts: [], arguments: []),
      ),
    );
    await select(tester, 'brief');
    expect(find.text('No case brief yet'), findsOneWidget);
  });

  for (final variant in GavelThemeVariant.values) {
    testWidgets('sections fit a 390px phone at 1.3x text in ${variant.label}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        GavelApp(initialLocation: Routes.caseFile, seed: seed),
      );
      await tester.pumpAndSettle();
      final appContext = tester.element(find.byType(SectionChips));
      // Apply the theme via its existing controller, as in the gallery.
      final themeController = Provider.of<ThemeController>(
        appContext,
        listen: false,
      );
      themeController.select(variant);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      for (final section in CaseSection.values) {
        await select(tester, section.name);
        final scroll = find.byKey(const PageStorageKey('case_scroll'));
        await tester.drag(scroll, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: section.name);
      }
    });
  }
}
