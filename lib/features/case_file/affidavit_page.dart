import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../state/case_controller.dart';

class AffidavitPage extends StatelessWidget {
  const AffidavitPage({super.key, required this.affidavitId});

  final String affidavitId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.caseFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CaseController>();
    final affidavit = controller.affidavitById(affidavitId);
    final witness = affidavit == null
        ? null
        : controller.witnessById(affidavit.witnessId);
    final theme = Theme.of(context);
    return WorkspacePage(
      title: 'Affidavit',
      leading: IconButton(
        key: const ValueKey('affidavit_back'),
        tooltip: 'Back to case',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => _back(context),
      ),
      child: controller.loadFailed
          ? Center(
              child: LoadFailure(
                title: 'Could not load the case',
                onRetry: controller.load,
              ),
            )
          : !controller.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : affidavit == null
          ? Center(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'Affidavit unavailable',
                message: 'This statement is not part of the active case.',
                actionLabel: 'Back to case',
                onAction: () => _back(context),
              ),
            )
          : WorkspaceScrollView(
              storageKey: PageStorageKey('affidavit_reading_$affidavitId'),
              maxWidth: LayoutTokens.reading,
              children: [
                Text('WITNESS AFFIDAVIT', style: theme.textTheme.labelSmall),
                const SizedBox(height: Spacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    affidavit.title,
                    style: theme.textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                if (witness != null)
                  Text(
                    '${witness.description} · ${witness.side.label}',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: Spacing.sm),
                Text(
                  controller.activeCase!.title,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.xxl),
                const Divider(),
                const SizedBox(height: Spacing.xxl),
                SelectableText(
                  affidavit.body,
                  key: const ValueKey('affidavit_full_text'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.85,
                  ),
                ),
                const SizedBox(height: Spacing.xxxl),
                Text(
                  'Demo case materials · Fictional sample packet',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
