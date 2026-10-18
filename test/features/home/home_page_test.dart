import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/core/widgets/stat_tile.dart';
import 'package:gavel/features/research/research_page.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

void main() {
  final clock = Clock.fixed(DateTime(2026, 10, 10, 15));

  testWidgets('Home shows the Harmon case, countdown, and repository counts', (
    tester,
  ) async {
    await pumpGavelApp(tester, clock: clock);

    expect(find.text('State v. Harmon'), findsOneWidget);
    expect(find.text('Trial in 23 days'), findsOneWidget);
    expect(find.text('42% team readiness'), findsWidgets);
    expect(find.text('Good afternoon, Sofia'), findsOneWidget);

    expect(
      tester.widget<StatTile>(find.byKey(GavelKeys.homeStatExhibits)).value,
      '14',
    );
    expect(
      tester.widget<StatTile>(find.byKey(GavelKeys.homeStatWitnesses)).value,
      '6',
    );
    expect(
      tester.widget<StatTile>(find.byKey(GavelKeys.homeStatTasks)).value,
      '12',
    );

    expect(find.text('Draft direct exam of Officer Reyes'), findsOneWidget);
  });

  testWidgets('Ask the case opens Research', (tester) async {
    await pumpGavelApp(tester, clock: clock);

    await tester.tap(find.byKey(GavelKeys.homeAskCase));
    await tester.pumpAndSettle();

    final page = find.byType(ResearchPage);
    expect(page, findsOneWidget);
    expect(GoRouter.of(tester.element(page)).state.uri.path, '/research');
  });
}
