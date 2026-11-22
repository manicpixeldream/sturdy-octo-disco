import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/data/repositories/task_repository.dart';
import 'package:gavel/state/task_controller.dart';

class _LiveTasks implements LiveTaskRepository {
  final snapshots = StreamController<List<TaskItem>>();
  final saves = <Completer<TaskItem>>[];

  @override
  Stream<List<TaskItem>> watchTasks() => snapshots.stream;

  @override
  Future<List<TaskItem>> fetchTasks() => throw UnimplementedError();

  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) {
    final save = Completer<TaskItem>();
    saves.add(save);
    return save.future;
  }
}

void main() {
  test(
    'task snapshots control readiness through rejected and racing writes',
    () async {
      final repository = _LiveTasks();
      final controller = TaskController(repository);
      addTearDown(() async {
        controller.dispose();
        await repository.snapshots.close();
      });
      final task = TaskItem(
        id: 'prep',
        title: 'Review exhibits',
        assigneeId: 'student',
        dueDate: DateTime(2026, 11, 23),
      );
      final load = controller.load();
      repository.snapshots.add([task]);
      await load;

      final rejected = controller.setCompleted(task.id, true);
      expect(controller.isSaving(task.id), isTrue);
      expect(controller.teamReadiness, 0);
      repository.saves.single.completeError(StateError('Write denied'));
      expect(await rejected, isFalse);
      expect(controller.saveFailed(task.id), isTrue);
      expect(controller.tasks, [task]);

      final retry = controller.retryCompletion(task.id);
      expect(controller.saveFailed(task.id), isFalse);
      final updated = task.copyWith(isDone: true, title: 'Updated by admin');
      repository.snapshots.add([updated]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.teamReadiness, 1);
      expect(controller.readinessFor('student'), 1);

      repository.saves.last.complete(task.copyWith(isDone: true));
      expect(await retry, isTrue);
      expect(controller.tasks, [updated]);

      final reopen = controller.setCompleted(task.id, false);
      repository.saves.last.completeError(StateError('Connection lost'));
      expect(await reopen, isFalse);
      expect(controller.saveFailed(task.id), isTrue);
      repository.snapshots.add([updated.copyWith(isDone: false)]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.saveFailed(task.id), isFalse);
      expect(await controller.retryCompletion(task.id), isFalse);
    },
  );
}
