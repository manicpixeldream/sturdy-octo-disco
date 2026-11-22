import '../core/clock.dart';
import '../core/dates.dart';
import '../core/storage/workspace_storage.dart';
import '../data/models/practice_session.dart';
import '../data/models/timing_rule.dart';
import '../data/repositories/schedule_repository.dart';
import 'load_controller.dart';

typedef AgendaItem = ({String? witnessId, TrialPhase phase});

class ScheduleController extends LoadController {
  ScheduleController(
    this._repository,
    this.clock,
    this.teammateId, {
    this.weeklyGoalMinutes = 180,
    this.storage,
  }) : _weekStart = monday(clock.now());
  final ScheduleRepository _repository;
  final Clock clock;
  final String teammateId;
  final int weeklyGoalMinutes;
  final WorkspaceStorage? storage;
  List<PracticeSession>? _sessions;
  final _agendas = <(String, String), List<AgendaItem>>{};
  PracticeSession? sessionById(String id) =>
      _sessions?.where((session) => session.id == id).firstOrNull;

  List<AgendaItem> agenda(String caseId, String sessionId) =>
      _agendas.putIfAbsent(
        (caseId, sessionId),
        () => List.unmodifiable(
          storage?.records(
                'agenda.$caseId.$sessionId',
                (item) => (
                  witnessId: item['witnessId'] as String?,
                  phase: TrialPhase.values.byName(item['phase']! as String),
                ),
              ) ??
              const <AgendaItem>[],
        ),
      );

  void setAgenda(String caseId, String sessionId, List<AgendaItem> items) {
    if (isDisposed || sessionById(sessionId) == null) return;
    _agendas[(caseId, sessionId)] = List.unmodifiable(items);
    storage?.write('agenda.$caseId.$sessionId', {
      for (final (index, item) in items.indexed)
        '$index': {'witnessId': item.witnessId, 'phase': item.phase.name},
    });
    notifyListeners();
  }

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
  Iterable<PracticeSession> get _selectedSessions => weekSessions.where(
    (session) =>
        _selectedDay == null ||
        daysBetween(_selectedDay!, session.startsAt.toLocal()) == 0,
  );

  List<PracticeSession> get visibleSessions {
    final now = clock.now();
    return _selectedSessions
        .where((session) => session.endsAt.isAfter(now))
        .toList();
  }

  List<PracticeSession> get pastSessions {
    final now = clock.now();
    return _selectedSessions
        .where((session) => !session.endsAt.isAfter(now))
        .toList()
        .reversed
        .toList();
  }

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
    void apply(List<PracticeSession> records) =>
        _sessions = List.unmodifiable(records);
    final repository = _repository;
    if (repository is LiveScheduleRepository) {
      await watchWith(repository.watchSessions(), apply);
    } else {
      await loadWith(repository.fetchSessions, apply);
    }
  }
}
