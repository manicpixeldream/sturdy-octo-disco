import '../core/clock.dart';
import '../core/dates.dart';
import '../data/models/practice_session.dart';
import '../data/repositories/schedule_repository.dart';
import 'load_controller.dart';

class ScheduleController extends LoadController {
  ScheduleController(
    this._repository,
    this.clock,
    this.teammateId, {
    this.weeklyGoalMinutes = 180,
  }) : _weekStart = monday(clock.now());
  final ScheduleRepository _repository;
  final Clock clock;
  final String teammateId;
  final int weeklyGoalMinutes;
  List<PracticeSession>? _sessions;
  bool get isLoaded => _sessions != null;
  DateTime _weekStart;
  DateTime get weekStart => _weekStart;
  DateTime? _selectedDay;
  DateTime? get selectedDay => _selectedDay;
  static DateTime monday(DateTime date) =>
      DateTime(date.year, date.month, date.day - date.weekday + 1);
  List<PracticeSession> get weekSessions =>
      (_sessions ?? <PracticeSession>[])
          .where(
            (s) =>
                s.participantIds.contains(teammateId) &&
                daysBetween(_weekStart, s.startsAt.toLocal()) >= 0 &&
                daysBetween(_weekStart, s.startsAt.toLocal()) < 7,
          )
          .toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  List<PracticeSession> get visibleSessions => weekSessions
      .where(
        (s) =>
            s.endsAt.isAfter(clock.now()) &&
            (_selectedDay == null ||
                daysBetween(_selectedDay!, s.startsAt.toLocal()) == 0),
      )
      .toList();
  int get plannedMinutes =>
      weekSessions.fold(0, (sum, s) => sum + s.durationMinutes);
  double get goalProgress => weeklyGoalMinutes <= 0
      ? 0
      : (plannedMinutes / weeklyGoalMinutes).clamp(0, 1);
  void changeWeek(int delta) {
    _weekStart = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + delta * 7,
    );
    _selectedDay = null;
    notifyListeners();
  }

  void selectDay(DateTime? day) {
    _selectedDay = day;
    notifyListeners();
  }

  void currentWeek() {
    _weekStart = monday(clock.now());
    _selectedDay = null;
    notifyListeners();
  }

  Future<void> load() async {
    await loadWith(
      _repository.fetchSessions,
      (items) => _sessions = List.unmodifiable(items),
    );
  }
}
