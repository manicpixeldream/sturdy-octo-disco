import 'load_controller.dart';
import '../core/storage/workspace_storage.dart';
import '../core/router/routes.dart';

import 'dart:math';

import '../data/models/task_item.dart';
import '../data/repositories/task_repository.dart';

class TaskController extends LoadController {
  TaskController(this._repository, {this.storage});

  final WorkspaceStorage? storage;

  final TaskRepository _repository;

  List<TaskItem>? _tasks;

  bool get isLoaded => _tasks != null;
  List<TaskItem> _roleTasks = const [];
  final _followUps = <TaskItem>[];
  final _random = Random.secure();

  void addFollowUp(
    String title,
    String assigneeId,
    DateTime dueDate, {
    String? workRoute,
  }) {
    if (isDisposed ||
        _repository is LiveTaskRepository ||
        title.trim().isEmpty) {
      return;
    }
    String id;
    do {
      id =
          'practice_follow_up_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(0x1000000)}';
    } while (tasks.any((task) => task.id == id));
    final task = TaskItem(
      id: id,
      title: title.trim(),
      assigneeId: assigneeId,
      dueDate: dueDate,
      workRoute: workRoute,
    );
    _followUps.add(task);
    storage?.putRecord('followUps', task.id, task.toMap());
    notifyListeners();
  }

  final _failedFollowUps = <String, TaskItem>{};
  final _savingFollowUps = <String>{};

  Future<bool> createPracticeFollowUp(
    String sessionId,
    String title,
    String assigneeId,
    DateTime dueDate,
  ) async {
    final body = title.trim();
    if (isDisposed || body.isEmpty) return false;
    final repository = _repository;
    final route = Routes.practiceAgenda(sessionId);
    if (repository is! FollowUpTaskRepository) {
      if (repository is LiveTaskRepository) return false;
      addFollowUp(body, assigneeId, dueDate, workRoute: route);
      return true;
    }

    if (!_savingFollowUps.add(sessionId)) return false;
    final date = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final previous = _failedFollowUps[sessionId];
    final task =
        previous != null &&
            previous.title == body &&
            previous.assigneeId == assigneeId &&
            previous.dueDate == date
        ? previous
        : TaskItem(
            id: 'follow_up_${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}',
            title: body,
            assigneeId: assigneeId,
            dueDate: date,
            workRoute: route,
          );
    _failedFollowUps[sessionId] = task;
    try {
      await (repository as FollowUpTaskRepository).createFollowUp(
        sessionId,
        task,
      );
      _failedFollowUps.remove(sessionId);
      return !isDisposed;
    } catch (_) {
      return false;
    } finally {
      _savingFollowUps.remove(sessionId);
    }
  }

  List<TaskItem> get tasks => List.unmodifiable(
    {
      ...{for (final t in _roleTasks) t.id: t},
      ...{for (final t in _followUps) t.id: t},
      ...{for (final t in _tasks ?? <TaskItem>[]) t.id: t},
    }.values,
  );
  void setRoleTasks(List<TaskItem> tasks) {
    if (isDisposed) return;
    _roleTasks = List.unmodifiable(tasks);
    notifyListeners();
  }

  final Set<String> _saving = {};
  final Map<String, bool> _saveErrors = {};
  bool isSaving(String id) => _saving.contains(id);
  bool saveFailed(String id) => _saveErrors.containsKey(id);

  Future<bool> retryCompletion(String id) {
    final desired = _saveErrors[id];
    return desired == null ? Future.value(false) : setCompleted(id, desired);
  }

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
      // Live snapshots own the list. The response may predate another edit
      // or the removal of this task.
      if (_repository is! LiveTaskRepository) {
        _tasks = List.unmodifiable([
          ...?_tasks?.where((t) => t.id != id),
          updated,
        ]);
      }
      return true;
    } catch (_) {
      if (!isDisposed &&
          (_repository is! LiveTaskRepository ||
              tasks.any((task) => task.id == id && task.isDone != completed))) {
        _saveErrors[id] = completed;
      }
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
    void apply(List<TaskItem> records) {
      _tasks = List.unmodifiable(records);
      if (_repository is LiveTaskRepository) {
        _saveErrors.removeWhere((id, desired) {
          final task = records.where((item) => item.id == id).firstOrNull;
          return task == null || task.isDone == desired;
        });
      }
      if (_repository is! LiveTaskRepository && storage != null) {
        final store = storage!;
        final restored = store.records('followUps', TaskItem.fromMap);
        final existing = _followUps.map((task) => task.id).toSet();
        _followUps.addAll(
          restored.where((task) => !existing.contains(task.id)),
        );
      }
    }

    final repository = _repository;
    if (repository is LiveTaskRepository) {
      await watchWith(repository.watchTasks(), apply);
    } else {
      await loadWith(_repository.fetchTasks, apply);
    }
  }

  static double _readiness(Iterable<TaskItem> tasks) {
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.isDone).length / tasks.length;
  }
}
