import 'package:gavel/core/clock.dart';
import 'package:gavel/core/storage/workspace_storage.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/mock_team_repository.dart';
import 'package:gavel/data/mock/mock_task_repository.dart';
import 'package:gavel/data/mock/mock_chat_repository.dart';
import 'package:gavel/data/repositories/chat_repository.dart';
import 'package:gavel/data/repositories/case_repository.dart';
import 'package:gavel/state/case_controller.dart';
import 'package:gavel/state/team_controller.dart';
import 'package:gavel/state/task_controller.dart';
import 'package:gavel/state/chat_controller.dart';

class ChatFixture {
  ChatFixture._(this.cases, this.team, this.tasks, this.chat);
  final CaseController cases;
  final TeamController team;
  final TaskController tasks;
  final ChatController chat;
  static Future<ChatFixture> create({
    ChatRepository? repository,
    CaseRepository? caseRepository,
    Duration timeout = const Duration(seconds: 20),
    WorkspaceStorage? storage,
  }) async {
    final seed = SeedData.harmon(today: DateTime(2026, 10, 26));
    final clock = Clock.fixed(DateTime(2026, 10, 26, 10));
    final cases = CaseController(
      caseRepository ??
          MockCaseRepository(
            activeCase: seed.caseFile,
            exhibits: seed.exhibits,
            witnesses: seed.witnesses,
          ),
      clock,
    );
    final team = TeamController(MockTeamRepository(seed.teammates));
    final tasks = TaskController(MockTaskRepository(seed.tasks));
    await Future.wait([cases.load(), team.load(), tasks.load()]);
    final chat = ChatController(
      repository ?? MockChatRepository(const [], storage),
      cases,
      team,
      tasks,
      clock,
      seed.currentTeammateId,
      requestTimeout: timeout,
      storage: storage,
    );
    await chat.load();
    return ChatFixture._(cases, team, tasks, chat);
  }

  void dispose() {
    chat.dispose();
    tasks.dispose();
    team.dispose();
    cases.dispose();
  }
}
