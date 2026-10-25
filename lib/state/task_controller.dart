import 'load_controller.dart';

import '../data/models/task_item.dart';
import '../data/repositories/task_repository.dart';

class TaskController extends LoadController {
  TaskController(this._repository);

  final TaskRepository _repository;

  List<TaskItem>? _tasks;

  bool get isLoaded => _tasks != null;
  List<TaskItem> _roleTasks = const [];
  List<TaskItem> get tasks => List.unmodifiable(
    {
      ...{for (final t in _roleTasks) t.id: t},
      ...{for (final t in _tasks ?? <TaskItem>[]) t.id: t},
    }.values,
  );
  void setRoleTasks(List<TaskItem> tasks) {
    if (isDisposed) return;
    _roleTasks = List.unmodifiable(tasks);
    notifyListeners();
  }

  final Set<String> _saving = {};
  final Set<String> _saveErrors = {};
  bool isSaving(String id) => _saving.contains(id);
  bool saveFailed(String id) => _saveErrors.contains(id);
  Future<bool> setCompleted(String id, bool completed) async {
    if (isDisposed || !isLoaded || isLoading || _saving.contains(id)) {
      return false;
    }
    final matches = tasks.where((t) => t.id == id);
    if (matches.isEmpty) return false;
    _saving.add(id);
    _saveErrors.remove(id);
    notifyListeners();
    try {
      final updated = await _repository.setCompleted(matches.first, completed);
      if (isDisposed) return false;
      _tasks = List.unmodifiable([
        ...?_tasks?.where((t) => t.id != id),
        updated,
      ]);
      return true;
    } catch (_) {
      if (!isDisposed) _saveErrors.add(id);
      return false;
    } finally {
      if (!isDisposed) {
        _saving.remove(id);
        notifyListeners();
      }
    }
  }

  int get doneCount => tasks.where((t) => t.isDone).length;

  /// Share of all team tasks that are done, from 0 to 1.
  double get teamReadiness => _readiness(tasks);

  /// Share of [teammateId]'s tasks that are done. 0 if they have none.
  double readinessFor(String teammateId) =>
      _readiness(tasks.where((t) => t.assigneeId == teammateId));

  /// Open tasks first (soonest due first), then done tasks.
  List<TaskItem> tasksFor(String teammateId) {
    return tasks.where((t) => t.assigneeId == teammateId).toList()
      ..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  Future<void> load() async {
    if (_saving.isNotEmpty) return;
    await loadWith(
      _repository.fetchTasks,
      (records) => _tasks = List.unmodifiable(records),
    );
  }

  static double _readiness(Iterable<TaskItem> tasks) {
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.isDone).length / tasks.length;
  }
}
