import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/widgets/gavel_bottom_nav.dart';
import 'package:gavel/core/widgets/workspace_columns.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/features/case_file/affidavit_page.dart';
import 'package:gavel/features/case_file/widgets/witness_card.dart';
import 'package:gavel/features/case_file/widgets/section_chips.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('GAVEL_CAPTURE')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('design_capture')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('/private/tmp/gavel-redesign');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final (family, files) in [
      ('Fraunces', ['Regular', 'SemiBold', 'Bold']),
      ('Inter', ['Regular', 'Medium', 'SemiBold', 'Bold']),
    ]) {
      final loader = FontLoader(family);
      for (final weight in files) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
  });

  Future<void> launch(
    WidgetTester tester,
    Size size, {
    String route = Routes.caseFile,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('design_capture'),
        child: GavelApp(seed: seed, initialLocation: route),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String section) async {
    final list = find.byKey(const PageStorageKey('case_scroll'));
    final scroll = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    final target = find.byKey(GavelKeys.caseSection(section));
    if (target.evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('case_more')));
      await tester.pumpAndSettle();
    }
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 780),
    const Size(390, 844),
    const Size(834, 1112),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'workspace adapts at ${size.width.toInt()}px without clipping or nav overlap',
      (tester) async {
        await launch(tester, size);
        final mobile = size.width < 760;
        expect(
          find.byType(GavelBottomNav),
          mobile ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey('workspace_sidebar')),
          mobile ? findsNothing : findsOneWidget,
        );
        if (mobile) {
          expect(
            tester
                .getRect(find.byKey(const PageStorageKey('case_scroll')))
                .bottom,
            lessThanOrEqualTo(tester.getRect(find.byType(GavelBottomNav)).top),
          );
        }
        expect(tester.takeException(), isNull);
        await _capture(tester, 'overview-${size.width.toInt()}');
        for (final section in [
          'brief',
          'exhibits',
          'stipulations',
          'rules',
          'affidavits',
        ]) {
          await select(tester, section);
          expect(tester.takeException(), isNull, reason: section);
        }
        final cards = find.byType(WitnessCard);
        expect(cards, findsNWidgets(6));
        final preview = tester.widget<Text>(
          find
              .descendant(
                of: cards.first,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Text &&
                      widget.data == seed.affidavits.first.body,
                ),
              )
              .first,
        );
        expect(preview.maxLines, 2);
        expect(preview.overflow, TextOverflow.ellipsis);
        final first = tester.getRect(cards.at(0));
        final second = tester.getRect(cards.at(1));
        if (size.width >= 834) {
          expect(first.top, second.top);
          expect(first.right, lessThan(second.left));
        } else {
          expect(first.bottom, lessThan(second.top));
        }
        await tester.drag(
          find.byKey(const PageStorageKey('case_scroll')),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'affidavits-${size.width.toInt()}');
        await Scrollable.ensureVisible(
          tester.element(cards.first),
          alignment: 0.3,
        );
        await tester.pumpAndSettle();
        await tester.tap(cards.first);
        await tester.pumpAndSettle();
        expect(find.byType(AffidavitPage), findsOneWidget);
        final full = find.byKey(const ValueKey('affidavit_full_text'));
        expect(
          tester.widget<SelectableText>(full).data,
          seed.affidavits.first.body,
        );
        expect(tester.getSize(full).width, lessThanOrEqualTo(680));
        expect(tester.takeException(), isNull);
        await _capture(tester, 'reader-${size.width.toInt()}');
      },
    );

    testWidgets(
      'Home and all global destinations fit ${size.width.toInt()}px',
      (tester) async {
        await launch(tester, size, route: Routes.home);
        expect(find.byType(WorkspaceColumns), findsOneWidget);
        if (size.width == 1440) {
          await _capture(tester, 'home-desktop');
        }
        for (final item in GavelBottomNav.items) {
          await tester.tap(find.byKey(item.key));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: item.label);
        }
      },
    );
  }

  testWidgets(
    'search and side filter combine, reset, and survive reader navigation',
    (tester) async {
      await launch(tester, const Size(390, 844));
      await select(tester, 'affidavits');
      final search = find.byKey(const ValueKey('affidavit_search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'fire');
      await tester.pumpAndSettle();
      expect(find.byType(WitnessCard), findsNWidgets(4));
      await tester.tap(find.byKey(const ValueKey('affidavit_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('affidavit_filter_defense')));
      await tester.pumpAndSettle();
      expect(find.byType(WitnessCard), findsNWidgets(2));
      final card = find.byType(WitnessCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('affidavit_back')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, 'fire');
      expect(find.byType(WitnessCard), findsNWidgets(2));
      await tester.enterText(search, 'no such witness');
      await tester.pumpAndSettle();
      expect(find.text('No matching witnesses'), findsOneWidget);
      final reset = find.text('Clear search and filters');
      await tester.ensureVisible(reset);
      await tester.pumpAndSettle();
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(find.byType(WitnessCard), findsNWidgets(6));
    },
  );

  testWidgets('reader supports direct URLs and unavailable source IDs', (
    tester,
  ) async {
    await launch(
      tester,
      const Size(834, 1112),
      route: Routes.affidavit('aff_okafor'),
    );
    expect(find.byType(AffidavitPage), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('affidavit_full_text')),
          )
          .data,
      seed.affidavits[1].body,
    );
    final context = tester.element(find.byType(AffidavitPage));
    GoRouter.of(context).go(Routes.affidavit('not_a_source'));
    await tester.pumpAndSettle();
    expect(find.text('Affidavit unavailable'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('affidavit_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(GavelKeys.caseHeader), findsOneWidget);
  });

  testWidgets(
    'mobile bottom controls respect the home-indicator safe area at 2x text',
    (tester) async {
      await launch(tester, const Size(390, 844));
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      for (final item in GavelBottomNav.items) {
        final rect = tester.getRect(find.byKey(item.key));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.bottom, lessThanOrEqualTo(844 - 34));
      }
      for (final section in [
        'brief',
        'affidavits',
        'exhibits',
        'stipulations',
        'rules',
      ]) {
        await select(tester, section);
        expect(tester.takeException(), isNull, reason: '2x text: $section');
      }
    },
  );

  testWidgets(
    'witness entries and secondary tabs respond to keyboard activation',
    (tester) async {
      await launch(tester, const Size(834, 1112));
      await select(tester, 'affidavits');
      final card = find.byType(WitnessCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      final ink = find
          .descendant(of: card, matching: find.byType(InkWell))
          .first;
      final focus = Focus.of(
        tester.element(
          find.descendant(of: ink, matching: find.byType(Padding)).first,
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AffidavitPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('affidavit_back')));
      await tester.pumpAndSettle();
      await select(tester, 'overview');
      final more = find.byKey(const ValueKey('case_more'));
      final moreInk = find
          .descendant(of: more, matching: find.byType(InkWell))
          .first;
      Focus.of(
        tester.element(
          find.descendant(of: moreInk, matching: find.byType(Padding)).first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(GavelKeys.caseSection('rules')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SectionChips>(find.byType(SectionChips)).selected,
        isNot(CaseSection.overview),
      );
    },
  );
}
