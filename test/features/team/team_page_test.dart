import 'package:gavel/core/keys.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/state/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:gavel/state/role_controller.dart';

import '../../helpers/pump_app.dart';

Future<void> reveal(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 50 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  testWidgets(
    'filters roles, assigns selected teammate, shares tasks with Home',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: '/team');
      await tester.tap(find.byKey(const ValueKey('team_filter_Defense')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('assign_role_defense_closing')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('assign_role_prosecution_closing')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('assign_role_witness_harmon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('assign_role_witness_okafor')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('team_filter_Witnesses')), findsNothing);
      final assign = find.byKey(const ValueKey('assign_role_defense_closing'));
      await reveal(tester, assign);
      await tester.tap(assign);
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('assign_role_submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      final sofia = find.byKey(const ValueKey('select_tm_sofia'));
      await reveal(tester, sofia);
      await tester.tap(sofia);
      await tester.pumpAndSettle();
      expect(find.text('Assign Sofia'), findsOneWidget);
      await reveal(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Role assigned'), findsOneWidget);
      final context = tester.element(find.text('Role assigned'));
      expect(context.read<RoleController>().assignments.length, 1);
      expect(context.read<TaskController>().tasks.length, 14);
      expect(context.read<TaskController>().tasksFor('tm_sofia').length, 6);
      await tester.tap(find.byKey(const ValueKey('assign_back')));
      await tester.pumpAndSettle();
      expect(find.text('1/14'), findsOneWidget);
      await tester.tap(find.byKey(GavelKeys.navHome));
      await tester.pumpAndSettle();
      expect(find.text('5 of 14 tasks done · 36%'), findsOneWidget);
      await tester.tap(find.byKey(GavelKeys.navTeam));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, 2500));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('team_filter_Prosecution')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('assign_role_witness_okafor')),
        findsOneWidget,
      );
    },
  );
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets('Team and assignment fit width $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGavelApp(tester, initialLocation: '/team');
      expect(tester.takeException(), isNull);
      await reveal(
        tester,
        find.byKey(const ValueKey('assign_role_prosecution_opening')),
      );
      await tester.tap(
        find.byKey(const ValueKey('assign_role_prosecution_opening')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Suggested teammates'), findsOneWidget);
      final theme = tester
          .element(find.text('Suggested teammates'))
          .read<ThemeController>();
      for (final variant in GavelThemeVariant.values) {
        theme.select(variant);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('unknown role deep link has a recoverable destination', (
    tester,
  ) async {
    await pumpGavelApp(tester, initialLocation: '/team/assign/unknown');
    expect(find.textContaining('This role could not be found'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assign_back')));
    await tester.pumpAndSettle();
    expect(find.text('Prepare as a team.'), findsOneWidget);
  });
}
