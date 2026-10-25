import '../models/task_item.dart';

abstract interface class TaskRepository {
  Future<List<TaskItem>> fetchTasks();

  /// Saves completion, including responsibility tasks supplied by RoleRepository.
  Future<TaskItem> setCompleted(TaskItem task, bool completed);
}
