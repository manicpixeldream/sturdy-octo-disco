import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/theme/spacing.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Team',
      child: WorkspaceScrollView(
        children: [
          Text(
            'Prepare as a team.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: Spacing.xxl),
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'Team',
            message: 'Roster, roles, and team chat. Coming in v0.7.',
          ),
        ],
      ),
    );
  }
}
