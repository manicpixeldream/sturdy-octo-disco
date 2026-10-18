import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/workspace_columns.dart';
import 'brief_fact_card.dart';
import 'brief_argument_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/case_brief.dart';

class CaseBriefSection extends StatelessWidget {
  const CaseBriefSection({
    super.key,
    this.factKeys,
    required this.brief,
    required this.isLoading,
    required this.failed,
    required this.onRetry,
    required this.sourceLabel,
    required this.onOpenEvidence,
  });

  final Map<String, GlobalKey>? factKeys;
  final CaseBrief? brief;
  final bool isLoading;
  final bool failed;
  final VoidCallback onRetry;
  final String? Function(EvidenceLink) sourceLabel;
  final ValueChanged<EvidenceLink> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(Spacing.xl),
        child: Center(
          child: CircularProgressIndicator(key: ValueKey('case_brief_loading')),
        ),
      );
    }
    if (failed) {
      return Column(
        children: [
          const EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load the case brief',
            message: 'The rest of your case materials are still available.',
          ),
          OutlinedButton(
            key: GavelKeys.caseBriefRetry,
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      );
    }
    final data = brief;
    if (data == null || (data.facts.isEmpty && data.arguments.isEmpty)) {
      return const EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No case brief yet',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Case brief'),
        Text(
          'Sample AI brief · Open each source to check the supporting material.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.lg),
        WorkspaceColumns(
          primary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Key facts & evidence'),
              for (final fact in data.facts)
                KeyedSubtree(
                  key: factKeys?[fact.id],
                  child: BriefFactCard(
                    key: GavelKeys.caseRecord(fact.id),
                    fact: fact,
                    sourceLabel: sourceLabel,
                    onOpenEvidence: onOpenEvidence,
                  ),
                ),
            ],
          ),
          secondary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Arguments & counters'),
              for (final argument in data.arguments)
                BriefArgumentCard(
                  key: GavelKeys.caseRecord(argument.id),
                  argument: argument,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
