import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_schedule_repository.dart';

void main() {
  test('demo dates are relative, sessions have valid durations and immutable results', () async {
    final repo = MockScheduleRepository.demo(DateTime(2026, 10, 26, 9), [
      'a',
      'b',
    ]);
    final sessions = await repo.fetchSessions();
    expect(sessions.length, 4);
    expect(sessions.first.startsAt, DateTime(2026, 10, 26, 17));
    expect(sessions.last.startsAt, DateTime(2026, 11, 3, 17));
    expect(
      sessions.every(
        (s) => s.durationMinutes > 0 && s.participantIds.contains('a'),
      ),
      isTrue,
    );
    expect(() => sessions.clear(), throwsUnsupportedError);
  });
}
