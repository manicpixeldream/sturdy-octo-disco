import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/features/home/home_page.dart';
import 'package:gavel/state/session_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../helpers/pump_app.dart';
import '../../state/load_recovery_test.dart'
    show FailingCaseRepository, FailingTaskRepository, FailingTeamRepository;

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  testWidgets('Home recovers from case, team, and task repository failures', (
    tester,
  ) async {
    final cases = FailingCaseRepository(seed);
    final team = FailingTeamRepository(seed.teammates);
    final tasks = FailingTaskRepository(seed.tasks);
    await pumpGavelApp(
      tester,
      seed: seed,
      caseRepository: cases,
      taskRepository: tasks,
      teamRepository: team,
    );
    expect(find.text('Could not load your workspace'), findsOneWidget);
    cases.fail = false;
    team.fail = false;
    tasks.fail = false;
    await tester.tap(find.byKey(const ValueKey('load_retry')));
    await tester.pumpAndSettle();
    expect(find.text('State v. Harmon'), findsOneWidget);
  });

  for (final route in [
    Routes.caseFile,
    Routes.affidavit('aff_okafor'),
    Routes.research,
  ]) {
    testWidgets('$route recovers from an initial case failure', (tester) async {
      final cases = FailingCaseRepository(seed);
      await pumpGavelApp(
        tester,
        initialLocation: route,
        seed: seed,
        caseRepository: cases,
      );
      expect(find.text('Could not load the case'), findsOneWidget);
      cases.fail = false;
      await tester.tap(find.byKey(const ValueKey('load_retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('load_error')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Home updates the greeting and countdown after midnight without reloading data',
    (tester) async {
      var now = DateTime(2026, 10, 17, 23, 59);
      await pumpGavelApp(tester, seed: seed, clock: Clock(() => now, false));
      expect(find.text('Good evening, Sofia'), findsOneWidget);
      expect(find.text('Trial in 23 days'), findsOneWidget);
      now = DateTime(2026, 10, 18, 0, 1);
      tester
          .element(find.byType(HomePage))
          .read<SessionController>()
          .refreshTime();
      await tester.pumpAndSettle();
      expect(find.text('Good morning, Sofia'), findsOneWidget);
      expect(find.text('Trial in 22 days'), findsOneWidget);
      expect(find.textContaining('dates reset on each launch'), findsOneWidget);
    },
  );
}
