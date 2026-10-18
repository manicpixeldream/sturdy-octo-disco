import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/workspace_columns.dart';
import '../../../data/models/case_file.dart';
import '../../../data/models/witness.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({
    super.key,
    required this.caseFile,
    required this.witnesses,
  });
  final CaseFile caseFile;
  final List<Witness> witnesses;

  @override
  Widget build(BuildContext context) => WorkspaceColumns(
    primary: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Case overview'),
        Text(
          caseFile.summary,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 19, height: 1.8),
        ),
      ],
    ),
    secondary: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Witnesses (${witnesses.length})'),
        for (final witness in witnesses)
          Padding(
            key: GavelKeys.caseRecord(witness.id),
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  witness.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${witness.side.label} · ${witness.description}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
