import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/affidavit.dart';
import '../../../data/models/trial_side.dart';
import '../../../data/models/witness.dart';
import 'witness_card.dart';

enum WitnessFilter { all, prosecution, defense }

class AffidavitsSection extends StatefulWidget {
  const AffidavitsSection({
    super.key,
    required this.affidavits,
    required this.witnessById,
    required this.onOpen,
  });

  final List<Affidavit> affidavits;
  final Witness? Function(String) witnessById;
  final ValueChanged<Affidavit> onOpen;

  @override
  State<AffidavitsSection> createState() => _AffidavitsSectionState();
}

class _AffidavitsSectionState extends State<AffidavitsSection> {
  final _search = TextEditingController();
  WitnessFilter _filter = WitnessFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = widget.affidavits.where((affidavit) {
      final witness = widget.witnessById(affidavit.witnessId);
      final matchesSide = switch (_filter) {
        WitnessFilter.all => true,
        WitnessFilter.prosecution => witness?.side == TrialSide.prosecution,
        WitnessFilter.defense => witness?.side == TrialSide.defense,
      };
      return matchesSide &&
          '${affidavit.title} ${witness?.description ?? ''} ${affidavit.body}'
              .toLowerCase()
              .contains(query);
    }).toList();
    final filterLabel = switch (_filter) {
      WitnessFilter.all => 'All sides',
      WitnessFilter.prosecution => 'Prosecution',
      WitnessFilter.defense => 'Defense',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Affidavits (${widget.affidavits.length})'),
        Text(
          'The people behind the testimony. Select a witness to read their statement.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.xl),
        TextField(
          key: const ValueKey('affidavit_search'),
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Search affidavits',
            hintText: 'Witness name, role, or statement',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('affidavit_search_clear'),
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${visible.length} of ${widget.affidavits.length} witnesses',
                  key: const ValueKey('affidavit_result_count'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            PopupMenuButton<WitnessFilter>(
              key: const ValueKey('affidavit_filter'),
              tooltip: 'Filter witnesses by side',
              initialValue: _filter,
              onSelected: (value) => setState(() => _filter = value),
              itemBuilder: (_) => [
                for (final (value, label) in [
                  (WitnessFilter.all, 'All sides'),
                  (WitnessFilter.prosecution, 'Prosecution'),
                  (WitnessFilter.defense, 'Defense'),
                ])
                  PopupMenuItem(
                    value: value,
                    key: ValueKey('affidavit_filter_${value.name}'),
                    child: Text(label),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    Text(
                      filterLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: Spacing.sm),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        if (widget.affidavits.isEmpty)
          const EmptyState(
            icon: Icons.description_outlined,
            title: 'No affidavits yet',
          )
        else if (visible.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: 'No matching witnesses',
            message: 'Try a different name or remove the side filter.',
            actionLabel: 'Clear search and filters',
            onAction: () => setState(() {
              _search.clear();
              _filter = WitnessFilter.all;
            }),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 2 : 1;
              final width =
                  (constraints.maxWidth - Spacing.lg * (columns - 1)) / columns;
              return Wrap(
                spacing: Spacing.lg,
                runSpacing: Spacing.lg,
                children: [
                  for (final affidavit in visible)
                    SizedBox(
                      width: width,
                      child: WitnessCard(
                        key: GavelKeys.caseRecord(affidavit.id),
                        affidavit: affidavit,
                        witness: widget.witnessById(affidavit.witnessId),
                        onOpen: () => widget.onOpen(affidavit),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
