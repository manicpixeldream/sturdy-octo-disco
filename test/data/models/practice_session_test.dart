import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/practice_session.dart';

void main() {
  test('session serialization, equality and immutable participants', () {
    final ids = ['a'];
    final session = PracticeSession(
      id: 'p',
      title: 'Practice',
      startsAt: DateTime(2026, 10, 26, 17),
      durationMinutes: 60,
      location: 'Room',
      participantIds: ids,
    );
    ids.clear();
    expect(session.participantIds, ['a']);
    expect(PracticeSession.fromMap(session.toMap()), session);
    expect(session.endsAt, DateTime(2026, 10, 26, 18));
    expect(session.copyWith(title: 'Scrimmage').title, 'Scrimmage');
    expect(() => session.participantIds.clear(), throwsUnsupportedError);
    expect(() => session.copyWith(durationMinutes: 0), throwsArgumentError);
  });
}
