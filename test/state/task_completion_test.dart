import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/mock/mock_role_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:gavel/state/role_controller.dart';

class FlakyTasks extends MockTaskRepository {
  FlakyTasks(super.tasks);
  bool fail = true;
  Completer<void>? pending;
  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) async {
    await pending?.future;
    if (fail) throw StateError('offline');
    return super.setCompleted(task, completed);
  }
}

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 26));
  test('completion updates metrics, reverses and survives both task and role reloads', () async {
    final tasks = TaskController(MockTaskRepository(seed.tasks));
    final roles = RoleController(
      MockRoleRepository(
        memberIds: {'tm_sofia'},
        dueDate: seed.caseFile.trialDate,
      ),
      tasks,
    );
    addTearDown(roles.dispose);
    addTearDown(tasks.dispose);
    await tasks.load();
    await roles.load();
    expect(await tasks.setCompleted('task_1', true), isTrue);
    expect(tasks.doneCount, 6);
    expect(tasks.readinessFor('tm_sofia'), .5);
    await roles.assign('prosecution_closing', 'tm_sofia');
    final roleTask = tasks.tasks.firstWhere((t) => t.id.startsWith('role_'));
    expect(await tasks.setCompleted(roleTask.id, true), isTrue);
    await tasks.load();
    await roles.load();
    expect(tasks.tasks.firstWhere((t) => t.id == roleTask.id).isDone, isTrue);
    expect(tasks.tasks.length, 14);
    expect(tasks.doneCount, 7);
    await tasks.setCompleted(roleTask.id, false);
    expect(tasks.doneCount, 6);
    expect(await tasks.setCompleted('missing', true), isFalse);
  });
  test('failed save preserves task and supports retry; duplicate saves are blocked', () async {
    final repo = FlakyTasks(seed.tasks);
    final tasks = TaskController(repo);
    addTearDown(tasks.dispose);
    await tasks.load();
    expect(await tasks.setCompleted('task_1', true), isFalse);
    expect(tasks.doneCount, 5);
    expect(tasks.saveFailed('task_1'), isTrue);
    repo.fail = false;
    repo.pending = Completer<void>();
    final save = tasks.setCompleted('task_1', true);
    expect(tasks.isSaving('task_1'), isTrue);
    expect(await tasks.setCompleted('task_1', true), isFalse);
    repo.pending!.complete();
    expect(await save, isTrue);
    expect(tasks.saveFailed('task_1'), isFalse);
    expect(tasks.doneCount, 6);
  });
  test(
    'disposed completion cannot notify or change controller state',
    () async {
      final repo = FlakyTasks(seed.tasks)
        ..fail = false
        ..pending = Completer<void>();
      final tasks = TaskController(repo);
      await tasks.load();
      final pending = tasks.setCompleted('task_1', true);
      tasks.dispose();
      repo.pending!.complete();
      expect(await pending, isFalse);
      expect(tasks.doneCount, 5);
    },
  );
}
