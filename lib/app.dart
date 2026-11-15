import 'data/repositories/chat_repository.dart';
import 'data/mock/mock_chat_repository.dart';
import 'state/chat_controller.dart';
import 'data/repositories/exam_repository.dart';
import 'data/services/exam_suggestion_service.dart';
import 'data/mock/mock_exam_repository.dart';
import 'data/mock/mock_exam_suggestion_service.dart';
import 'state/exam_controller.dart';
import 'data/mock/mock_schedule_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'state/schedule_controller.dart';
import 'data/mock/mock_role_repository.dart';
import 'data/repositories/role_repository.dart';
import 'state/role_controller.dart';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/clock.dart';
import 'data/services/research_service.dart';
import 'data/mock/mock_research_service.dart';
import 'state/research_controller.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'data/mock/mock_case_repository.dart';
import 'data/mock/mock_case_brief_service.dart';
import 'data/services/case_brief_service.dart';
import 'data/mock/mock_task_repository.dart';
import 'data/mock/mock_team_repository.dart';
import 'data/mock/seed_data.dart';
import 'data/repositories/case_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/team_repository.dart';
import 'state/case_controller.dart';
import 'features/onboarding/onboarding.dart';
import 'state/session_controller.dart';
import 'core/storage/workspace_storage.dart';
import 'state/task_controller.dart';
import 'state/team_controller.dart';
import 'state/theme_controller.dart';

class GavelApp extends StatefulWidget {
  const GavelApp({
    super.key,
    this.initialLocation = Routes.home,
    this.onboarding,
    this.storage,
    this.clock,
    this.seed,
    this.caseRepository,
    this.teamRepository,
    this.taskRepository,
    this.caseBriefService,
    this.researchService,
    this.roleRepository,
    this.scheduleRepository,
    this.examRepository,
    this.examSuggestionService,
    this.chatRepository,
  });

  final String initialLocation;
  final Onboarding? onboarding;
  final WorkspaceStorage? storage;
  final Clock? clock;
  final SeedData? seed;
  final CaseRepository? caseRepository;
  final TeamRepository? teamRepository;
  final TaskRepository? taskRepository;
  final CaseBriefService? caseBriefService;
  final ResearchService? researchService;
  final RoleRepository? roleRepository;
  final ScheduleRepository? scheduleRepository;
  final ExamRepository? examRepository;
  final ExamSuggestionService? examSuggestionService;
  final ChatRepository? chatRepository;

  @override
  State<GavelApp> createState() => _GavelAppState();
}

class _GavelAppState extends State<GavelApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
    onboarding: widget.onboarding,
  );
  late final ThemeController _theme = ThemeController();
  late final SessionController _session;
  late final CaseController _case;
  late final TeamController _team;
  late final TaskController _tasks;
  late final ResearchController _research;
  late final RoleController _roles;
  late final ScheduleController _schedule;
  late final ExamController _exams;
  late final ChatController _chat;

  @override
  void initState() {
    super.initState();
    final clock = widget.clock ?? Clock();
    final storage = widget.storage;
    final savedStart = storage?.read(
      'start',
      (value) => DateTime.parse(value as String),
    );
    final workspaceStart = savedStart ?? clock.now();
    if (savedStart == null) {
      storage?.write('start', workspaceStart.toIso8601String());
    }
    final seed = widget.seed ?? SeedData.harmon(today: workspaceStart);
    _session = SessionController(
      currentTeammateId: seed.currentTeammateId,
      clock: clock,
    );
    final caseRepository =
        widget.caseRepository ??
        MockCaseRepository(
          activeCase: seed.caseFile,
          exhibits: seed.exhibits,
          witnesses: seed.witnesses,
          affidavits: seed.affidavits,
          stipulations: seed.stipulations,
          timingRules: seed.timingRules,
        );
    _case = CaseController(
      caseRepository,
      clock,
      storage: storage,
      briefService:
          widget.caseBriefService ?? MockCaseBriefService(seed.caseBrief),
    )..load();
    _research = ResearchController(
      widget.researchService ??
          MockResearchService(caseRepository: caseRepository),
      _case,
      storage: storage,
    );
    _exams = ExamController(
      widget.examRepository ?? MockExamRepository(const [], storage),
      widget.examSuggestionService ?? MockExamSuggestionService(),
      _case,
      _research,
    );
    _team = TeamController(
      widget.teamRepository ?? MockTeamRepository(seed.teammates),
    )..load();
    _tasks = TaskController(
      widget.taskRepository ?? MockTaskRepository(seed.tasks, storage),
      storage: storage,
    )..load();
    _schedule = ScheduleController(
      widget.scheduleRepository ??
          MockScheduleRepository.demo(
            workspaceStart,
            seed.teammates.map((m) => m.id).toList(),
          ),
      clock,
      seed.currentTeammateId,
      storage: storage,
    )..load();
    _chat = ChatController(
      widget.chatRepository ?? MockChatRepository(const [], storage),
      _case,
      _team,
      _tasks,
      _session.clock,
      _session.currentTeammateId,
      storage: storage,
    );
    _roles = RoleController(
      widget.roleRepository ??
          MockRoleRepository(
            memberIds: seed.teammates.map((m) => m.id).toSet(),
            dueDate: seed.caseFile.trialDate,
            storage: storage,
          ),
      _tasks,
    )..load();
  }

  @override
  void dispose() {
    _router.dispose();
    _theme.dispose();
    _session.dispose();
    _chat.dispose();
    _exams.dispose();
    _research.dispose();
    _case.dispose();
    _team.dispose();
    _schedule.dispose();
    _roles.dispose();
    _tasks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _theme),
        ChangeNotifierProvider.value(value: _session),
        ChangeNotifierProvider.value(value: _case),
        ChangeNotifierProvider.value(value: _team),
        ChangeNotifierProvider.value(value: _tasks),
        ChangeNotifierProvider.value(value: _roles),
        ChangeNotifierProvider.value(value: _schedule),
        ChangeNotifierProvider.value(value: _exams),
        ChangeNotifierProvider.value(value: _chat),
        ChangeNotifierProvider.value(value: _research),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp.router(
          title: 'Gavel',
          debugShowCheckedModeBanner: false,
          // No darkTheme: the variant picked in ThemeController wins, not the
          // OS dark mode setting.
          theme: themeController.variant.data,
          routerConfig: _router,
          builder: (context, child) {
            final storage = widget.storage;
            if (storage == null) return child!;
            return ValueListenableBuilder<bool>(
              valueListenable: storage.saveFailed,
              child: child,
              builder: (context, failed, child) => Column(
                children: [
                  if (failed)
                    Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Semantics(
                            liveRegion: true,
                            child: const Text(
                              'Browser storage is unavailable. Changes may be lost on reload.',
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: child!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
