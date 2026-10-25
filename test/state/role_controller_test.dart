import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_role_repository.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/models/role_assignment.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/state/role_controller.dart';
import 'package:gavel/state/task_controller.dart';

class FailingRoles extends MockRoleRepository {
  FailingRoles() : super(memberIds: {'a'}, dueDate: DateTime(2026));
  bool fail = true;
  Completer<void>? pending;
  @override
  Future<RoleAssignment> assign(String roleId, String teammateId) async {
    await pending?.future;
    if (fail) throw StateError('offline');
    return super.assign(roleId, teammateId);
  }
}

void main() {
  test('atomic assignment adds tasks, lowers completion, survives reload, rejects duplicates', () async {
    final tasks = TaskController(
      MockTaskRepository([
        TaskItem(
          id: 'old',
          title: 'Done',
          assigneeId: 'a',
          dueDate: DateTime(2026),
          isDone: true,
        ),
      ]),
    );
    final repository = MockRoleRepository(
      memberIds: {'a'},
      dueDate: DateTime(2026),
    );
    final roles = RoleController(repository, tasks);
    addTearDown(roles.dispose);
    addTearDown(tasks.dispose);
    await tasks.load();
    await roles.load();
    expect(tasks.teamReadiness, 1);
    expect(await roles.assign('defense_closing', 'a'), isTrue);
    expect(tasks.tasksFor('a').length, 3);
    expect(tasks.teamReadiness, closeTo(1 / 3, .001));
    expect(await roles.assign('defense_closing', 'a'), isFalse);
    await tasks.load();
    await roles.load();
    expect(tasks.tasks.length, 3);
    expect(roles.assignments.length, 1);
    await expectLater(
      repository.assign('defense_opening', 'unknown'),
      throwsStateError,
    );
    expect((await repository.fetchAssignments()).length, 1);
  });
  test(
    'failure changes neither assignment nor tasks and supports retry',
    () async {
      final tasks = TaskController(MockTaskRepository([]));
      final repo = FailingRoles();
      final roles = RoleController(repo, tasks);
      addTearDown(roles.dispose);
      addTearDown(tasks.dispose);
      await tasks.load();
      await roles.load();
      expect(await roles.assign('defense_closing', 'a'), isFalse);
      expect(roles.saveFailed, isTrue);
      expect(tasks.tasks, isEmpty);
      expect(roles.assignments, isEmpty);
      repo.fail = false;
      expect(await roles.assign('defense_closing', 'a'), isTrue);
      expect(roles.saveFailed, isFalse);
    },
  );
  test('concurrent and disposed assignment completions are guarded', () async {
    final tasks = TaskController(MockTaskRepository([]));
    final repo = FailingRoles()
      ..fail = false
      ..pending = Completer<void>();
    final roles = RoleController(repo, tasks);
    await roles.load();
    final first = roles.assign('defense_closing', 'a');
    expect(await roles.assign('defense_opening', 'a'), isFalse);
    roles.dispose();
    repo.pending!.complete();
    expect(await first, isFalse);
    expect(tasks.tasks, isEmpty);
    tasks.dispose();
  });
}
