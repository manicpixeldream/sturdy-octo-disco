import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/data/services/research_service.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/repositories/case_repository.dart';
import 'package:gavel/data/repositories/task_repository.dart';
import 'package:gavel/data/repositories/team_repository.dart';
import 'package:gavel/data/services/case_brief_service.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps a single widget inside a themed [MaterialApp] and [Scaffold].
Future<void> pumpGavelWidget(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? GavelTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Pumps the real app (router and providers) and waits for it to settle.
Future<void> pumpGavelApp(
  WidgetTester tester, {
  String initialLocation = Routes.home,
  Clock? clock,
  SeedData? seed,
  CaseRepository? caseRepository,
  TeamRepository? teamRepository,
  TaskRepository? taskRepository,
  CaseBriefService? caseBriefService,
  ResearchService? researchService,
}) async {
  await tester.pumpWidget(
    GavelApp(
      initialLocation: initialLocation,
      clock: clock,
      seed: seed,
      caseRepository: caseRepository,
      teamRepository: teamRepository,
      taskRepository: taskRepository,
      caseBriefService: caseBriefService,
      researchService: researchService,
    ),
  );
  await tester.pumpAndSettle();
}
