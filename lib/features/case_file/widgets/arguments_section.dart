import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/timing_rule.dart';
import '../../../state/case_controller.dart';

class ArgumentsSection extends StatelessWidget {
  const ArgumentsSection({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    final cases = context.read<CaseController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Argument drafts'),
        const Text(
          'Drafts save as you type and reset when you reload the app.',
        ),
        for (final phase in const [TrialPhase.opening, TrialPhase.closing]) ...[
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
        ],
      ],
    );
  }
}
