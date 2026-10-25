import '../models/task_item.dart';
import '../repositories/task_repository.dart';

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(List<TaskItem> tasks)
    : _tasks = {for (final t in tasks) t.id: t};
  final Map<String, TaskItem> _tasks;
  @override
  Future<List<TaskItem>> fetchTasks() async => List.unmodifiable(_tasks.values);
  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) async {
    final updated = (_tasks[task.id] ?? task).copyWith(isDone: completed);
    _tasks[task.id] = updated;
    return updated;
  }
}
