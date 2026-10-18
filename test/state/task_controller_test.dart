import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/state/task_controller.dart';

void main() {
  final due = DateTime(2026, 10, 12);
  final later = DateTime(2026, 10, 20);

  final tasks = [
    TaskItem(id: 'a', title: 'Open soon', assigneeId: 'tm_sofia', dueDate: due),
    TaskItem(
      id: 'b',
      title: 'Done',
      assigneeId: 'tm_sofia',
      dueDate: due,
      isDone: true,
    ),
    TaskItem(
      id: 'c',
      title: 'Open later',
      assigneeId: 'tm_sofia',
      dueDate: later,
    ),
    TaskItem(
      id: 'd',
      title: 'Marcus',
      assigneeId: 'tm_marcus',
      dueDate: due,
      isDone: true,
    ),
  ];

  late TaskController controller;

  setUp(() async {
    controller = TaskController(MockTaskRepository(tasks));
    await controller.load();
  });

  test('teamReadiness is the share of all tasks that are done', () {
    expect(controller.doneCount, 2);
    expect(controller.teamReadiness, 0.5);
  });

  test('readinessFor uses only that teammate\'s tasks', () {
    expect(controller.readinessFor('tm_sofia'), closeTo(1 / 3, 0.0001));
    expect(controller.readinessFor('tm_marcus'), 1);
    expect(controller.readinessFor('tm_nobody'), 0);
  });

  test('tasksFor puts open tasks first, soonest due first', () {
    expect(controller.tasksFor('tm_sofia').map((t) => t.id), ['a', 'c', 'b']);
  });
}
