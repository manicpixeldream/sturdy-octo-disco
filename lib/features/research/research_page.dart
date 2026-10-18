import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/theme/spacing.dart';

class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'AI research',
      child: WorkspaceScrollView(
        children: [
          Text(
            'Research with context.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: Spacing.xxl),
          const EmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'Research',
            message: 'Ask the case and build your library. Coming in v0.6.',
          ),
        ],
      ),
    );
  }
}
