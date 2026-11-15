import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/features/onboarding/onboarding.dart';
import 'package:gavel/features/onboarding/welcome_page.dart';
import 'package:material_ui/material_ui.dart';

Future<void> loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
    await loadFont('Fraunces', [
      for (final weight in ['Regular', 'SemiBold', 'Bold'])
        'assets/fonts/Fraunces-$weight.ttf',
    ]);
    await loadFont('Inter', [
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Inter-$weight.ttf',
    ]);
  });

  final screens = {
    'welcome': Routes.welcome,
    'home': Routes.home,
    'case': Routes.caseFile,
    'affidavit': Routes.affidavit('aff_reyes'),
    'examination': Routes.exam('wit_reyes'),
    'research': Routes.research,
    'source': Routes.researchSource('source_daubert'),
    'team': Routes.team,
    'assign_role': Routes.assignRole('defense_closing'),
    'team_chat': Routes.teamChat,
    'task': Routes.teamTask('task_1'),
    'profile': Routes.me,
    'schedule': Routes.schedule,
    'practice_agenda': Routes.practiceAgenda('practice_0'),
    'gallery': Routes.gallery,
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} at 390 × 844', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);

      final isWelcome = entry.value == Routes.welcome;
      await tester.pumpWidget(
        GavelApp(
          initialLocation: entry.value,
          onboarding: isWelcome ? Onboarding() : null,
          clock: Clock.fixed(DateTime(2026, 10, 26, 19)),
        ),
      );
      await tester.pumpAndSettle();
      if (isWelcome) expect(find.byType(WelcomePage), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('baselines/${entry.key}.png'),
      );
    }, skip: !Platform.isMacOS);
  }
}
