import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/features/case_file/case_page.dart';
import 'package:gavel/features/home/home_page.dart';
import 'package:gavel/features/me/me_page.dart';
import 'package:gavel/features/research/research_page.dart';
import 'package:gavel/features/team/team_page.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

void main() {
  final tabs = [
    (key: GavelKeys.navHome, page: HomePage, path: '/home'),
    (key: GavelKeys.navCase, page: CasePage, path: '/case'),
    (key: GavelKeys.navResearch, page: ResearchPage, path: '/research'),
    (key: GavelKeys.navTeam, page: TeamPage, path: '/team'),
    (key: GavelKeys.navMe, page: MePage, path: '/me'),
  ];

  testWidgets('all five nav items render', (tester) async {
    await pumpGavelApp(tester);

    for (final tab in tabs) {
      expect(find.byKey(tab.key), findsOneWidget, reason: '${tab.key}');
    }
  });

  testWidgets('tapping each nav item opens its tab', (tester) async {
    await pumpGavelApp(tester);

    for (final tab in tabs) {
      await tester.tap(find.byKey(tab.key));
      await tester.pumpAndSettle();

      final page = find.byType(tab.page);
      expect(page, findsOneWidget, reason: '${tab.page}');
      expect(GoRouter.of(tester.element(page)).state.uri.path, tab.path);
    }
  });

  testWidgets('a tab keeps its state when switching away and back', (
    tester,
  ) async {
    await pumpGavelApp(tester);
    final homeBefore = tester.element(find.byType(HomePage));

    await tester.tap(find.byKey(GavelKeys.navTeam));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.byKey(GavelKeys.navHome));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(HomePage)), same(homeBefore));
  });
}
