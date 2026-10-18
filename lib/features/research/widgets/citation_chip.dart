import 'package:material_ui/material_ui.dart';

import '../../../data/models/research_source.dart';

class CitationChip extends StatelessWidget {
  const CitationChip({
    super.key,
    required this.source,
    required this.number,
    required this.onOpen,
  });
  final ResearchSource source;
  final int number;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: source.citation,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: TextButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.description_outlined, size: 16),
        label: Text(
          '$number · ${source.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}
