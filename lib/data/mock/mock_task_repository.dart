import '../../core/storage/workspace_storage.dart';
import '../models/task_item.dart';
import '../repositories/task_repository.dart';

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(List<TaskItem> tasks, [this.storage])
    : _tasks = {
        for (final task in tasks) task.id: task,
        for (final task in storage?.records('tasks', TaskItem.fromMap) ?? [])
          task.id: task,
      };
  final WorkspaceStorage? storage;
  final Map<String, TaskItem> _tasks;
  @override
  Future<List<TaskItem>> fetchTasks() async => List.unmodifiable(_tasks.values);
  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) async {
    final updated = (_tasks[task.id] ?? task).copyWith(isDone: completed);
    _tasks[task.id] = updated;
    storage?.putRecord('tasks', task.id, updated.toMap());
    return updated;
  }
}
