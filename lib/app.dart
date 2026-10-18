import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/clock.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'data/mock/mock_case_repository.dart';
import 'data/mock/mock_task_repository.dart';
import 'data/mock/mock_team_repository.dart';
import 'data/mock/seed_data.dart';
import 'data/repositories/case_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/team_repository.dart';
import 'state/case_controller.dart';
import 'state/session_controller.dart';
import 'state/task_controller.dart';
import 'state/team_controller.dart';
import 'state/theme_controller.dart';

class GavelApp extends StatefulWidget {
  const GavelApp({
    super.key,
    this.initialLocation = Routes.home,
    this.clock,
    this.seed,
    this.caseRepository,
    this.teamRepository,
    this.taskRepository,
  });

  final String initialLocation;
  final Clock? clock;
  final SeedData? seed;
  final CaseRepository? caseRepository;
  final TeamRepository? teamRepository;
  final TaskRepository? taskRepository;

  @override
  State<GavelApp> createState() => _GavelAppState();
}

class _GavelAppState extends State<GavelApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );
  late final ThemeController _theme = ThemeController();
  late final SessionController _session;
  late final CaseController _case;
  late final TeamController _team;
  late final TaskController _tasks;

  @override
  void initState() {
    super.initState();
    final clock = widget.clock ?? Clock();
    final seed = widget.seed ?? SeedData.harmon(today: clock.now());
    _session = SessionController(
      currentTeammateId: seed.currentTeammateId,
      clock: clock,
    );
    _case = CaseController(
      widget.caseRepository ??
          MockCaseRepository(
            activeCase: seed.caseFile,
            exhibits: seed.exhibits,
            witnesses: seed.witnesses,
          ),
      clock,
    )..load();
    _team = TeamController(
      widget.teamRepository ?? MockTeamRepository(seed.teammates),
    )..load();
    _tasks = TaskController(
      widget.taskRepository ?? MockTaskRepository(seed.tasks),
    )..load();
  }

  @override
  void dispose() {
    _router.dispose();
    _theme.dispose();
    _session.dispose();
    _case.dispose();
    _team.dispose();
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
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp.router(
          title: 'Gavel',
          debugShowCheckedModeBanner: false,
          // No darkTheme: the variant picked in ThemeController wins, not the
          // OS dark mode setting.
          theme: themeController.variant.data,
          routerConfig: _router,
        ),
      ),
    );
  }
}
