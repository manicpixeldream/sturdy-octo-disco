import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/models/task_item.dart';

void main() {
  test('repository stores completion for both seeded and role tasks without duplication', () async {
    final task = TaskItem(
      id: 'task',
      title: 'Prepare',
      assigneeId: 'a',
      dueDate: DateTime(2026),
    );
    final repo = MockTaskRepository([task]);
    await repo.setCompleted(task, true);
    expect((await repo.fetchTasks()).single.isDone, isTrue);
    final roleTask = task.copyWith(id: 'role_task');
    await repo.setCompleted(roleTask, true);
    await repo.setCompleted(roleTask, false);
    final all = await repo.fetchTasks();
    expect(all.length, 2);
    expect(all.last.isDone, isFalse);
    expect(() => all.clear(), throwsUnsupportedError);
  });
}
