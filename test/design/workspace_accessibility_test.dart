import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  final routes = [
    Routes.welcome,
    Routes.home,
    Routes.caseFile,
    Routes.affidavit('aff_reyes'),
    Routes.exam('wit_reyes'),
    Routes.research,
    Routes.researchSource('source_daubert'),
    Routes.team,
    Routes.assignRole('defense_closing'),
    Routes.teamChat,
    Routes.teamTask('task_1'),
    Routes.me,
    Routes.schedule,
    Routes.practiceAgenda('practice_0'),
  ];

  for (final width in [320.0, 390.0]) {
    for (final route in routes) {
      testWidgets(
        '$route fits enlarged text and labels tappable controls at ${width.toInt()}px',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final semantics = tester.ensureSemantics();

          try {
            await pumpGavelApp(
              tester,
              initialLocation: route,
              clock: Clock.fixed(DateTime(2026, 10, 26, 19)),
            );

            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
