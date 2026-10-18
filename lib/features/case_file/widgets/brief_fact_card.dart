import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../data/models/case_brief.dart';

class BriefFactCard extends StatelessWidget {
  const BriefFactCard({
    super.key,
    required this.fact,
    required this.sourceLabel,
    required this.onOpenEvidence,
  });

  final BriefFact fact;
  final String? Function(EvidenceLink) sourceLabel;
  final ValueChanged<EvidenceLink> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.text, style: text.bodyLarge),
          for (final link in fact.evidence) ...[
            const SizedBox(height: Spacing.sm),
            if (sourceLabel(link) case final label?)
              TextButton.icon(
                key: GavelKeys.caseEvidence(fact.id, link.sourceId),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => onOpenEvidence(link),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(label),
              )
            else
              const Text('Source unavailable'),
            Text(link.note, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
