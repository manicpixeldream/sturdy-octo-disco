import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/exhibit.dart';

class ExhibitsSection extends StatelessWidget {
  const ExhibitsSection({super.key, required this.exhibits});
  final List<Exhibit> exhibits;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: 'Exhibits (${exhibits.length})'),
      for (final exhibit in exhibits)
        Padding(
          key: GavelKeys.caseRecord(exhibit.id),
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  exhibit.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exhibit.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      exhibit.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (exhibits.isEmpty)
        const EmptyState(icon: Icons.folder_outlined, title: 'No exhibits yet'),
    ],
  );
}
