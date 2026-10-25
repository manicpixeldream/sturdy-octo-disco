import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/models/practice_session.dart';
import 'package:gavel/data/mock/mock_schedule_repository.dart';
import 'package:gavel/state/schedule_controller.dart';

class FlakySchedule extends MockScheduleRepository {
  FlakySchedule(super.sessions);
  bool fail = true;
  @override
  Future<List<PracticeSession>> fetchSessions() async {
    if (fail) throw StateError('offline');
    return super.fetchSessions();
  }
}

void main() {
  PracticeSession session(
    String id,
    DateTime start,
    int minutes, {
    String member = 'a',
  }) => PracticeSession(
    id: id,
    title: id,
    startsAt: start,
    durationMinutes: minutes,
    location: 'Room',
    participantIds: [member],
  );
  test('calendar weeks, personal filtering, ongoing sessions, goal totals and day filters', () async {
    final controller = ScheduleController(
      MockScheduleRepository([
        session('past', DateTime(2026, 10, 26, 9), 60),
        session('ongoing', DateTime(2026, 10, 28, 9, 30), 60),
        session('future', DateTime(2026, 11, 1, 17), 90),
        session('other', DateTime(2026, 10, 29, 17), 90, member: 'b'),
        session('next', DateTime(2026, 11, 2, 17), 30),
      ]),
      Clock.fixed(DateTime(2026, 10, 28, 10)),
      'a',
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.weekStart, DateTime(2026, 10, 26));
    expect(controller.plannedMinutes, 210);
    expect(controller.goalProgress, 1);
    expect(controller.visibleSessions.map((s) => s.id), ['ongoing', 'future']);
    controller.selectDay(DateTime(2026, 11, 1));
    expect(controller.visibleSessions.single.id, 'future');
    expect(controller.plannedMinutes, 210);
    controller.selectDay(DateTime(2026, 10, 29));
    expect(controller.visibleSessions, isEmpty);
    controller.changeWeek(1);
    expect(controller.selectedDay, isNull);
    expect(controller.plannedMinutes, 30);
    expect(controller.goalProgress, closeTo(1 / 6, .001));
    controller.currentWeek();
    expect(controller.weekStart, DateTime(2026, 10, 26));
  });
  test('empty and failure states recover', () async {
    final repo = FlakySchedule([]);
    final controller = ScheduleController(
      repo,
      Clock.fixed(DateTime(2026)),
      'a',
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loadFailed, isTrue);
    repo.fail = false;
    await controller.load();
    expect(controller.isLoaded, isTrue);
    expect(controller.loadFailed, isFalse);
    expect(controller.goalProgress, 0);
    expect(controller.visibleSessions, isEmpty);
  });
}
