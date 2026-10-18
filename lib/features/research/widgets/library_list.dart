import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/research_source.dart';
import '../../../state/research_controller.dart';
import 'source_tile.dart';

class LibraryList extends StatefulWidget {
  const LibraryList({
    super.key,
    required this.controller,
    required this.onOpen,
  });
  final ResearchController controller;
  final ValueChanged<String> onOpen;
  @override
  State<LibraryList> createState() => _LibraryListState();
}

class _LibraryListState extends State<LibraryList> {
  bool _all = false;
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources =
        (_all ? widget.controller.sources : widget.controller.savedSources)
            .where(
              (s) => '${s.title} ${s.citation}'.toLowerCase().contains(
                _query.trim().toLowerCase(),
              ),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your reading shelf',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Saved for this session. The alpha library clears on reload.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.lg),
        Wrap(
          spacing: Spacing.sm,
          children: [
            TextButton(
              key: const ValueKey('library_saved'),
              onPressed: () => setState(() => _all = false),
              child: Text(
                'Saved (${widget.controller.savedSources.length})',
                style: TextStyle(
                  fontWeight: _all ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('library_all'),
              onPressed: () => setState(() => _all = true),
              child: Text(
                'All sources',
                style: TextStyle(
                  fontWeight: _all ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          key: const ValueKey('library_search'),
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            labelText: 'Search sources',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('library_search_clear'),
                    tooltip: 'Clear source search',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        if (sources.isEmpty)
          EmptyState(
            icon: Icons.bookmarks_outlined,
            title: _query.isNotEmpty
                ? 'No matching sources'
                : _all
                ? 'No sources available'
                : 'No saved sources yet',
            message: 'Browse the source catalogue or open a citation in Ask.',
            actionLabel: !_all ? 'Browse sources' : null,
            onAction: !_all ? () => setState(() => _all = true) : null,
          ),
        for (final kind in ResearchSourceKind.values)
          if (sources.any((s) => s.kind == kind)) ...[
            SectionHeader(title: kind.label),
            for (final source in sources.where((s) => s.kind == kind))
              SourceTile(
                key: ValueKey('source_tile_${source.id}'),
                source: source,
                saved: widget.controller.isSaved(source.id),
                onOpen: () => widget.onOpen(source.id),
                onToggleSaved: () => widget.controller.toggleSaved(source.id),
              ),
            const SizedBox(height: Spacing.lg),
          ],
      ],
    );
  }
}
