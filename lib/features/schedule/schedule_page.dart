import '../../core/widgets/trial_countdown.dart';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spacing.dart';
import '../../core/dates.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/widgets/workspace_columns.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/load_failure.dart';
import '../../state/schedule_controller.dart';
import '../../state/case_controller.dart';
import '../../state/session_controller.dart';
import 'widgets/week_strip.dart';
import 'widgets/session_tile.dart';
import 'widgets/weekly_goal_card.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleController>();
    final caseState = context.watch<CaseController>();
    final session = context.watch<SessionController>();
    return WorkspacePage(
      title: 'Practice schedule',
      leading: IconButton(
        key: const ValueKey('schedule_back'),
        tooltip: 'Back to Profile',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(Routes.me),
      ),
      child: WorkspaceScrollView(
        children: [
          Text(
            'Make time for the courtroom.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: Spacing.md),
          if (caseState.loadFailed)
            LoadFailure(
              title: 'Trial countdown unavailable',
              onRetry: caseState.load,
            )
          else if (caseState.activeCase != null)
            TrialCountdown(
              days: daysBetween(
                session.clock.now(),
                caseState.activeCase!.trialDate,
              ),
            ),
          const SizedBox(height: Spacing.md),
          const Text(
            'Demo schedule · Dates reset each launch. Times use your device’s local time. Sessions are read-only in this alpha.',
          ),
          if (schedule.loadFailed)
            LoadFailure(title: 'Schedule unavailable', onRetry: schedule.load)
          else if (!schedule.isLoaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            const SizedBox(height: Spacing.xl),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('schedule_prev_week'),
                  tooltip: 'Previous week',
                  onPressed: () => schedule.changeWeek(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    'Week of ${DateFormat.yMMMd().format(schedule.weekStart)}',
                    key: const ValueKey('schedule_week'),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  key: const ValueKey('schedule_next_week'),
                  tooltip: 'Next week',
                  onPressed: () => schedule.changeWeek(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            TextButton(
              key: const ValueKey('schedule_this_week'),
              onPressed: schedule.currentWeek,
              child: const Text('This week'),
            ),
            WeekStrip(
              weekStart: schedule.weekStart,
              selectedDay: schedule.selectedDay,
              onSelected: schedule.selectDay,
            ),
            WorkspaceColumns(
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: schedule.selectedDay == null
                        ? 'Upcoming in selected week'
                        : 'Upcoming · ${DateFormat.MMMd().format(schedule.selectedDay!)}',
                  ),
                  if (schedule.visibleSessions.isEmpty)
                    const Text(
                      'No upcoming practices for this selection.',
                      key: ValueKey('schedule_empty'),
                    ),
                  for (final practice in schedule.visibleSessions)
                    SessionTile(
                      key: ValueKey('session_${practice.id}'),
                      session: practice,
                      now: session.clock.now(),
                    ),
                ],
              ),
              secondary: Padding(
                padding: const EdgeInsets.only(top: Spacing.lg),
                child: WeeklyGoalCard(
                  minutes: schedule.plannedMinutes,
                  target: schedule.weeklyGoalMinutes,
                  progress: schedule.goalProgress,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
