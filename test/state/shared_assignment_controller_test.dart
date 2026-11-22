import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_role_repository.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/models/role_assignment.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/data/repositories/role_repository.dart';
import 'package:gavel/data/repositories/task_repository.dart';
import 'package:gavel/state/role_controller.dart';
import 'package:gavel/state/task_controller.dart';

class _CloudRoles extends MockRoleRepository implements LiveRoleRepository {
  _CloudRoles()
    : super(memberIds: const {'student'}, dueDate: DateTime(2026, 12, 14));

  final snapshots = StreamController<RoleRoster>();
  final pending = Completer<RoleAssignment>();

  @override
  Stream<RoleRoster> watchRoleRoster() => snapshots.stream;

  @override
  Future<RoleAssignment> assignForCase(
    String caseId,
    String roleId,
    String teammateId,
  ) => pending.future;
}

class _CloudFollowUps extends MockTaskRepository
    implements FollowUpTaskRepository {
  _CloudFollowUps() : super(const []);

  final attempts = <(String, TaskItem)>[];

  @override
  Future<void> createFollowUp(String sessionId, TaskItem task) async {
    attempts.add((sessionId, task));
    if (attempts.length == 1) throw StateError('Connection lost');
  }
}

void main() {
  test(
    'a stale role response cannot add tasks or replace a newer case roster',
    () async {
      final repository = _CloudRoles();
      final tasks = TaskController(MockTaskRepository(const []));
      final roles = RoleController(repository, tasks);
      addTearDown(() async {
        roles.dispose();
        tasks.dispose();
        await repository.snapshots.close();
      });

      final role = MockRoleRepository.roles.first;
      final assignment = await repository.assign(role.id, 'student');
      final load = roles.load();
      repository.snapshots.add(('first', [role], []));
      await load;
      expect(
        await roles.assign(role.id, 'student', expectedCaseId: 'old'),
        isFalse,
      );
      final save = roles.assign(role.id, 'student', expectedCaseId: 'first');
      expect(roles.isSaving, isTrue);

      repository.snapshots.add(('replacement', [role], []));
      await Future<void>.delayed(Duration.zero);
      repository.pending.complete(assignment);
      expect(await save, isFalse);
      expect(roles.caseId, 'replacement');
      expect(roles.assignments, isEmpty);
      expect(tasks.tasks, isEmpty);
    },
  );

  test(
    'follow-up retry preserves the ID and waits for shared task snapshots',
    () async {
      final repository = _CloudFollowUps();
      final tasks = TaskController(repository);
      addTearDown(tasks.dispose);
      final date = DateTime(2026, 12, 14, 17);
      Future<bool> save() => tasks.createPracticeFollowUp(
        'practice_1',
        ' Review exhibit ',
        'student',
        date,
      );

      expect(await save(), isFalse);
      expect(await save(), isTrue);
      expect(repository.attempts[0], repository.attempts[1]);
      final (session, task) = repository.attempts.first;
      expect(session, 'practice_1');
      expect(task.title, 'Review exhibit');
      expect(task.dueDate, DateTime(2026, 12, 14));
      expect(task.workRoute, '/me/schedule/practice_1');
      expect(tasks.tasks, isEmpty);
    },
  );
}
