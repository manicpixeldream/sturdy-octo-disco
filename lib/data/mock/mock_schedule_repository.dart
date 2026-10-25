import '../models/practice_session.dart';
import '../repositories/schedule_repository.dart';

class MockScheduleRepository implements ScheduleRepository {
  MockScheduleRepository(List<PracticeSession> sessions)
    : _sessions = List.unmodifiable(sessions);
  factory MockScheduleRepository.demo(DateTime today, List<String> members) =>
      MockScheduleRepository([
        for (final (days, title, minutes) in [
          (0, 'Opening statements', 45),
          (2, 'Witness preparation', 60),
          (4, 'Full team scrimmage', 90),
          (8, 'Closing arguments', 60),
        ])
          PracticeSession(
            id: 'practice_$days',
            title: title,
            startsAt: DateTime(today.year, today.month, today.day + days, 17),
            durationMinutes: minutes,
            location: 'Mock trial practice room',
            participantIds: members,
          ),
      ]);
  final List<PracticeSession> _sessions;
  @override
  Future<List<PracticeSession>> fetchSessions() async => _sessions;
}
