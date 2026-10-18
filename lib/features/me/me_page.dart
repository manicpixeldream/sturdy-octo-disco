import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/keys.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/theme/spacing.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: 'Profile',
      child: WorkspaceScrollView(
        children: [
          Text(
            'Your preparation, in one place.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: Spacing.xxl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmptyState(
                icon: Icons.person_outline,
                title: 'Profile',
                message: 'Your tasks and practice schedule. Coming in v0.8.',
              ),
              OutlinedButton(
                key: GavelKeys.meOpenGallery,
                onPressed: () => context.push(Routes.gallery),
                child: const Text('Design system and themes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
