import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/features/research/research_page.dart';
import 'package:gavel/state/research_controller.dart';
import 'package:gavel/state/theme_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('GAVEL_CAPTURE')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('research_capture')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('/private/tmp/gavel-v06');
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
    for (final (family, weights) in [
      ('Fraunces', ['Regular', 'SemiBold', 'Bold']),
      ('Inter', ['Regular', 'Medium', 'SemiBold', 'Bold']),
    ]) {
      final loader = FontLoader(family);
      for (final weight in weights) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
  });
  Future<void> launch(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('research_capture'),
        child: GavelApp(
          initialLocation: Routes.research,
          seed: seed,
          clock: Clock.fixed(DateTime(2026, 10, 17)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 780),
    const Size(390, 844),
    const Size(834, 1112),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'Research Ask, reply, Library, and source reading fit ${size.width.toInt()}px',
      (tester) async {
        await launch(tester, size);
        expect(tester.takeException(), isNull);
        await _capture(tester, 'ask-${size.width.toInt()}');
        await tester.enterText(
          find.byKey(const ValueKey('research_input')),
          'Build the case timeline',
        );
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(ResearchPage));
        expect(context.read<ResearchController>().messages, hasLength(2));
        expect(tester.takeException(), isNull);
        await _capture(tester, 'reply-${size.width.toInt()}');
        await tester.tap(find.byKey(const ValueKey('research_library_mode')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('library_all')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, 'library-${size.width.toInt()}');
        final source = find.byKey(const ValueKey('source_tile_source_daubert'));
        await tester.ensureVisible(source);
        await tester.pumpAndSettle();
        await tester.tap(source);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, 'source-${size.width.toInt()}');
      },
    );
  }

  testWidgets(
    'composer stays above the keyboard and safe area at enlarged text',
    (tester) async {
      await launch(tester, const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.view.resetPadding);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('research_input'));
      expect(tester.getRect(input).bottom, lessThanOrEqualTo(844 - 300));
      expect(tester.takeException(), isNull);
      await tester.enterText(input, 'expert evidence');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        tester
            .element(find.byType(ResearchPage))
            .read<ResearchController>()
            .messages,
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final theme in GavelThemeVariant.values) {
    testWidgets('Research remains readable in ${theme.label} with 1.5x text', (
      tester,
    ) async {
      await launch(tester, const Size(390, 844));
      tester
          .element(find.byType(ResearchPage))
          .read<ThemeController>()
          .select(theme);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('research_input')),
        'eyewitness identification',
      );
      await tester.tap(find.byKey(const ValueKey('research_send')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
