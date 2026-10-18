import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/mock/mock_team_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/case_file.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/data/models/teammate.dart';
import 'package:gavel/state/case_controller.dart';
import 'package:gavel/state/session_controller.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:gavel/state/team_controller.dart';

class FailingCaseRepository extends MockCaseRepository {
  FailingCaseRepository(SeedData seed)
    : super(
        activeCase: seed.caseFile,
        exhibits: seed.exhibits,
        witnesses: seed.witnesses,
        affidavits: seed.affidavits,
        stipulations: seed.stipulations,
        timingRules: seed.timingRules,
      );
  bool fail = true;
  @override
  Future<CaseFile> fetchActiveCase() async {
    if (fail) throw StateError('offline');
    return super.fetchActiveCase();
  }
}

class FailingTaskRepository extends MockTaskRepository {
  FailingTaskRepository(super.tasks);
  bool fail = true;
  @override
  Future<List<TaskItem>> fetchTasks() async {
    if (fail) throw StateError('offline');
    return super.fetchTasks();
  }
}

class FailingTeamRepository extends MockTeamRepository {
  FailingTeamRepository(super.teammates);
  bool fail = true;
  Future<List<Teammate>>? pending;
  @override
  Future<List<Teammate>> fetchTeammates() async {
    if (fail) throw StateError('offline');
    return pending ?? super.fetchTeammates();
  }
}

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  test(
    'all repository controllers expose failure and recover on retry',
    () async {
      final caseRepo = FailingCaseRepository(seed);
      final taskRepo = FailingTaskRepository(seed.tasks);
      final teamRepo = FailingTeamRepository(seed.teammates);
      final cases = CaseController(caseRepo, const Clock());
      final tasks = TaskController(taskRepo);
      final team = TeamController(teamRepo);
      addTearDown(cases.dispose);
      addTearDown(tasks.dispose);
      addTearDown(team.dispose);
      await Future.wait([cases.load(), tasks.load(), team.load()]);
      expect([
        cases.loadFailed,
        tasks.loadFailed,
        team.loadFailed,
      ], everyElement(isTrue));
      expect([
        cases.isLoading,
        tasks.isLoading,
        team.isLoading,
      ], everyElement(isFalse));
      caseRepo.fail = false;
      taskRepo.fail = false;
      teamRepo.fail = false;
      await Future.wait([cases.load(), tasks.load(), team.load()]);
      expect([
        cases.loadFailed,
        tasks.loadFailed,
        team.loadFailed,
      ], everyElement(isFalse));
      expect([
        cases.isLoaded,
        tasks.isLoaded,
        team.isLoaded,
      ], everyElement(isTrue));
      expect(tasks.tasks, seed.tasks);
    },
  );

  test('stale repository results and disposed completions do not notify or overwrite', () async {
    final repo = FailingTeamRepository(seed.teammates)..fail = false;
    final team = TeamController(repo);
    final first = Completer<List<Teammate>>();
    repo.pending = first.future;
    final older = team.load();
    repo.pending = Future.value([seed.teammates.first]);
    await team.load();
    first.complete(seed.teammates);
    await older;
    expect(team.teammates, [seed.teammates.first]);
    final late = Completer<List<Teammate>>();
    repo.pending = late.future;
    final load = team.load();
    team.dispose();
    late.complete(seed.teammates);
    await load;
  });

  testWidgets(
    'active clock ticks and lifecycle resume refresh minute-dependent UI state',
    (tester) async {
      var now = DateTime(2026, 10, 17, 23, 59);
      final session = SessionController(
        currentTeammateId: 'tm_sofia',
        clock: Clock(() => now),
      );
      var notifications = 0;
      session.addListener(() => notifications++);
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      now = DateTime(2026, 10, 18, 0, 0);
      await tester.pump(const Duration(seconds: 15));
      expect(notifications, 1);
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = DateTime(2026, 10, 18, 12);
      await tester.pump(const Duration(seconds: 30));
      expect(notifications, 1);
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifications, 2);
      session.dispose();
    },
  );
}
