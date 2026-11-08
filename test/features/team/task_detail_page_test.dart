import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gavel/core/router/routes.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'own task offers checklist; teammate task is read-only; unknown task can return',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: Routes.teamTask('task_1'));
      expect(find.byKey(const ValueKey('task_open_checklist')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('task_open_checklist')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 4 personal tasks complete'), findsOneWidget);
    },
  );
  testWidgets(
    'unknown task deep link reports unavailable rather than showing another task',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: Routes.teamTask('unknown'));
      expect(
        find.textContaining('This task is no longer available'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('task_detail_back')));
      await tester.pumpAndSettle();
      expect(find.text('Prepare as a team.'), findsOneWidget);
    },
  );
}
