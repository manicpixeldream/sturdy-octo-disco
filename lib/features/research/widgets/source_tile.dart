import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../data/models/research_source.dart';

class SourceTile extends StatelessWidget {
  const SourceTile({
    super.key,
    required this.source,
    required this.saved,
    required this.onOpen,
    required this.onToggleSaved,
  });
  final ResearchSource source;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: GavelCard(
          onTap: onOpen,
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                source.citation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: Spacing.sm),
      Padding(
        padding: const EdgeInsets.only(top: Spacing.sm),
        child: IconButton(
          key: ValueKey('library_save_${source.id}'),
          tooltip: saved ? 'Remove from saved sources' : 'Save source',
          onPressed: onToggleSaved,
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
        ),
      ),
    ],
  );
}
