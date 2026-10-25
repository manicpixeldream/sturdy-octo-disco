import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/state/theme_controller.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

class OfflineTasks extends MockTaskRepository {
  OfflineTasks(super.tasks);
  bool fail = true;
  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) async {
    if (fail) throw StateError('offline');
    return super.setCompleted(task, completed);
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 50 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  final clock = Clock.fixed(DateTime(2026, 10, 26, 10));
  testWidgets(
    'personal checklist updates Profile, Home and Team consistently',
    (tester) async {
      await pumpGavelApp(tester, initialLocation: '/me', clock: clock);
      expect(find.text('1 of 4 personal tasks complete'), findsOneWidget);
      expect(find.byKey(const ValueKey('my_task_task_5')), findsNothing);
      final task = find.byKey(const ValueKey('my_task_task_1'));
      await reveal(tester, task);
      await tester.tap(task);
      await tester.pumpAndSettle();
      expect(find.text('2 of 4 personal tasks complete'), findsOneWidget);
      await tester.tap(find.byKey(GavelKeys.navHome));
      await tester.pumpAndSettle();
      expect(find.text('6 of 12 tasks done · 50%'), findsOneWidget);
      await tester.tap(find.byKey(GavelKeys.navTeam));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '6 of 12 preparation tasks complete. New responsibilities may lower this percentage.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(GavelKeys.navMe));
      await tester.pumpAndSettle();
      final state = tester
          .element(find.text('2 of 4 personal tasks complete'))
          .read<TaskController>();
      await state.setCompleted('task_1', false);
      await tester.pumpAndSettle();
      expect(find.text('1 of 4 personal tasks complete'), findsOneWidget);
    },
  );
  testWidgets('save failure keeps checkbox unchanged and provides retry', (
    tester,
  ) async {
    final repo = OfflineTasks(SeedData.harmon(today: clock.now()).tasks);
    await pumpGavelApp(
      tester,
      initialLocation: '/me',
      clock: clock,
      taskRepository: repo,
    );
    final task = find.byKey(const ValueKey('my_task_task_1'));
    await reveal(tester, task);
    await tester.tap(task);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(task).value, isFalse);
    final retry = find.byKey(const ValueKey('retry_task_task_1'));
    expect(retry, findsOneWidget);
    repo.fail = false;
    await reveal(tester, retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(task).value, isTrue);
  });
  for (final (key, path) in [
    ('me_quick_schedule', '/me/schedule'),
    ('me_quick_case', '/case'),
    ('me_quick_research', '/research'),
    ('me_quick_team', '/team'),
    ('me_open_gallery', '/gallery'),
  ]) {
    testWidgets('quick access $key opens $path', (tester) async {
      await pumpGavelApp(tester, initialLocation: '/me', clock: clock);
      final target = key == 'me_open_gallery'
          ? find.byKey(GavelKeys.meOpenGallery)
          : find.byKey(ValueKey(key));
      await reveal(tester, target);
      final router = GoRouter.of(tester.element(target));
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, path);
    });
  }
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets('Profile fits $width with enlarged text and shared themes', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGavelApp(tester, initialLocation: '/me', clock: clock);
      final theme = tester
          .element(find.text('1 of 4 personal tasks complete'))
          .read<ThemeController>();
      for (final variant in GavelThemeVariant.values) {
        theme.select(variant);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
