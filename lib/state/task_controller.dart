import 'package:flutter/foundation.dart';

import '../data/models/task_item.dart';
import '../data/repositories/task_repository.dart';

class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;

  List<TaskItem>? _tasks;

  bool get isLoaded => _tasks != null;
  List<TaskItem> get tasks => _tasks ?? const [];
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
    _tasks = await _repository.fetchTasks();
    notifyListeners();
  }

  static double _readiness(Iterable<TaskItem> tasks) {
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.isDone).length / tasks.length;
  }
}
