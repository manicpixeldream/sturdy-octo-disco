import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/state/theme_controller.dart';
import 'package:gavel/data/mock/mock_schedule_repository.dart';
import 'package:gavel/data/models/practice_session.dart';

import '../../helpers/pump_app.dart';

class OfflineSchedule extends MockScheduleRepository {
  OfflineSchedule() : super([]);
  bool fail = true;
  @override
  Future<List<PracticeSession>> fetchSessions() async {
    if (fail) throw StateError('offline');
    return super.fetchSessions();
  }
}

void main() {
  final clock = Clock.fixed(DateTime(2026, 10, 26, 10));
  testWidgets(
    'week strip filters sessions without changing weekly goal; week navigation resets day',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpGavelApp(tester, initialLocation: '/me/schedule', clock: clock);
      expect(find.text('195 / 180 minutes planned'), findsOneWidget);
      expect(find.text('Opening statements'), findsOneWidget);
      expect(find.text('Full team scrimmage'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('schedule_day_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('schedule_empty')), findsOneWidget);
      expect(find.text('195 / 180 minutes planned'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('schedule_all_week')));
      await tester.pumpAndSettle();
      expect(find.text('Opening statements'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('schedule_next_week')));
      await tester.pumpAndSettle();
      expect(find.text('Closing arguments'), findsOneWidget);
      expect(find.text('60 / 180 minutes planned'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('schedule_this_week')));
      await tester.pumpAndSettle();
      expect(find.text('Opening statements'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('schedule_back')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 4 personal tasks complete'), findsOneWidget);
    },
  );
  testWidgets('schedule load failure retries to an empty state', (
    tester,
  ) async {
    final repo = OfflineSchedule();
    await pumpGavelApp(
      tester,
      initialLocation: '/me/schedule',
      clock: clock,
      scheduleRepository: repo,
    );
    expect(find.text('Schedule unavailable'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.byKey(const ValueKey('load_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule_empty')), findsOneWidget);
  });
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets('Schedule fits $width with enlarged text and shared themes', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGavelApp(tester, initialLocation: '/me/schedule', clock: clock);
      final theme = tester
          .element(find.text('Practice schedule'))
          .read<ThemeController>();
      for (final variant in GavelThemeVariant.values) {
        theme.select(variant);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
