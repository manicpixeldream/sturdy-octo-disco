import '../models/task_item.dart';
import '../repositories/task_repository.dart';

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(List<TaskItem> tasks) : _tasks = List.unmodifiable(tasks);

  final List<TaskItem> _tasks;

  @override
  Future<List<TaskItem>> fetchTasks() async => _tasks;
}
