import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../data/models/citation.dart';
import '../../state/case_controller.dart';
import '../../state/research_controller.dart';

class SourceDetailPage extends StatelessWidget {
  const SourceDetailPage({super.key, required this.sourceId});
  final String sourceId;

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.research);
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ResearchController>();
    final cases = context.watch<CaseController>();
    final source = controller.sourceById(sourceId);
    final text = Theme.of(context).textTheme;
    return WorkspacePage(
      title: 'Source',
      leading: IconButton(
        key: const ValueKey('source_back'),
        tooltip: 'Back to research',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => _back(context),
      ),
      child: cases.loadFailed || controller.loadFailed
          ? Center(
              child: LoadFailure(
                title: 'Could not load this source',
                onRetry: cases.loadFailed ? cases.load : controller.load,
              ),
            )
          : !controller.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : source == null
          ? const Center(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'Source unavailable',
                message: 'This source is not in the active case’s catalogue.',
              ),
            )
          : WorkspaceScrollView(
              maxWidth: LayoutTokens.reading,
              storageKey: PageStorageKey('source_reading_$sourceId'),
              children: [
                Text(source.kind.label.toUpperCase(), style: text.labelSmall),
                const SizedBox(height: Spacing.lg),
                Semantics(
                  header: true,
                  child: Text(source.title, style: text.displaySmall),
                ),
                const SizedBox(height: Spacing.md),
                SelectableText(
                  source.citation,
                  key: const ValueKey('source_citation'),
                  style: text.bodySmall,
                ),
                const SizedBox(height: Spacing.lg),
                OutlinedButton.icon(
                  key: ValueKey('research_save_$sourceId'),
                  onPressed: () => controller.toggleSaved(sourceId),
                  icon: Icon(
                    controller.isSaved(sourceId)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(
                    controller.isSaved(sourceId)
                        ? 'Saved to Library'
                        : 'Save to Library',
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Text(source.context, style: text.bodySmall),
                const SizedBox(height: Spacing.xxl),
                SelectableText(
                  source.content,
                  key: const ValueKey('source_content'),
                  style: text.bodyLarge?.copyWith(fontSize: 18, height: 1.8),
                ),
                if (source.url case final url?) ...[
                  const SizedBox(height: Spacing.xl),
                  const SectionHeader(title: 'Official source'),
                  SelectableText(url, style: text.bodySmall),
                  TextButton.icon(
                    key: const ValueKey('source_copy_link'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy official link'),
                    onPressed: () async {
                      try {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Official link copied'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Select the address above to copy it.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
                const SizedBox(height: Spacing.xxl),
                const Divider(),
                const SectionHeader(title: 'Cited in'),
                if (controller.citationsFor(sourceId).isEmpty)
                  Text(
                    'Not cited in this workspace yet. Saving a source does not create a citation.',
                    style: text.bodySmall,
                  ),
                for (final citation in controller.citationsFor(sourceId))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: ListTile(
                      key: ValueKey('source_usage_${citation.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(switch (citation.location) {
                        CitationLocation.answer => 'Research answer',
                        CitationLocation.caseBrief => 'Case brief',
                        CitationLocation.examQuestion => 'Examination question',
                      }, style: text.titleSmall),
                      subtitle: Text(citation.label),
                      trailing:
                          citation.location == CitationLocation.examQuestion
                          ? null
                          : const Icon(Icons.arrow_outward, size: 18),
                      onTap: switch (citation.location) {
                        CitationLocation.answer => () => context.go(
                          Routes.researchAnswer(citation.referenceId),
                        ),
                        CitationLocation.caseBrief => () => context.go(
                          Routes.caseBrief(citation.referenceId),
                        ),
                        CitationLocation.examQuestion => null,
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
