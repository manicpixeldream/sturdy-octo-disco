import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/dates.dart';

void main() {
  test('daysBetween counts calendar days and ignores time of day', () {
    expect(
      daysBetween(DateTime(2026, 10, 10, 23, 59), DateTime(2026, 11, 2, 0, 1)),
      23,
    );
    expect(daysBetween(DateTime(2026, 10, 10), DateTime(2026, 10, 10)), 0);
    expect(daysBetween(DateTime(2026, 10, 11), DateTime(2026, 10, 10)), -1);
  });

  test('greetingFor splits the day into morning, afternoon, and evening', () {
    expect(greetingFor(DateTime(2026, 10, 10, 8)), 'Good morning');
    expect(greetingFor(DateTime(2026, 10, 10, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 10, 19)), 'Good evening');
  });

  test('dueLabel and trialCountdownLabel cover the nearby day cases', () {
    final today = DateTime(2026, 10, 10);
    expect(dueLabel(DateTime(2026, 10, 10), today), 'Due today');
    expect(dueLabel(DateTime(2026, 10, 11), today), 'Due tomorrow');
    expect(dueLabel(DateTime(2026, 10, 12), today), 'Due in 2 days');
    expect(dueLabel(DateTime(2026, 10, 9), today), '1 day overdue');
    expect(dueLabel(DateTime(2026, 10, 8), today), '2 days overdue');

    expect(trialCountdownLabel(23), 'Trial in 23 days');
    expect(trialCountdownLabel(1), 'Trial tomorrow');
    expect(trialCountdownLabel(0), 'Trial today');
    expect(trialCountdownLabel(-1), 'Trial was yesterday');
    expect(trialCountdownLabel(-4), 'Trial was 4 days ago');
  });
}
