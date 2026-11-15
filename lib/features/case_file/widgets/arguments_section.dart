import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/router/routes.dart';
import '../../../state/research_controller.dart';
import '../../research/research_context.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/timing_rule.dart';
import '../../../state/case_controller.dart';

class ArgumentsSection extends StatelessWidget {
  const ArgumentsSection({super.key, required this.caseId, this.selectedPhase});
  final String? selectedPhase;

  final String caseId;

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseController>();
    final research = context.watch<ResearchController>();
    final phases = [TrialPhase.opening, TrialPhase.closing];
    if (phases.any((phase) => phase.name == selectedPhase)) {
      phases.removeWhere((phase) => phase.name != selectedPhase);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Argument drafts'),
        const Text('Drafts save as you type in this browser.'),
        for (final phase in phases) ...[
          const SizedBox(height: Spacing.lg),
          TextFormField(
            key: ValueKey('argument_${phase.name}'),
            initialValue: cases.argumentDraft(caseId, phase),
            onChanged: (text) => cases.updateArgumentDraft(caseId, phase, text),
            decoration: InputDecoration(
              labelText: phase.label,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
            minLines: 5,
            maxLines: 12,
          ),
          Wrap(
            spacing: Spacing.sm,
            children: [
              TextButton.icon(
                key: ValueKey('argument_research_${phase.name}'),
                icon: const Icon(Icons.search),
                label: const Text('Research this draft'),
                onPressed: () => context.push(
                  Routes.research,
                  extra: ResearchContext(
                    label: phase.label,
                    attachSource: (id) async =>
                        cases.attachArgumentSource(caseId, phase, id),
                  ),
                ),
              ),
              for (final id in cases.argumentSources(caseId, phase))
                InputChip(
                  label: Text(research.sourceById(id)?.title ?? id),
                  onPressed: () => context.push(Routes.researchSource(id)),
                  deleteButtonTooltipMessage:
                      'Remove ${research.sourceById(id)?.title ?? id}',
                  onDeleted: () =>
                      cases.detachArgumentSource(caseId, phase, id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
