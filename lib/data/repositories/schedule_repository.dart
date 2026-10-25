import '../models/practice_session.dart';

abstract interface class ScheduleRepository {
  Future<List<PracticeSession>> fetchSessions();
}
