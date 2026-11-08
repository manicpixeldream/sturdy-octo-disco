import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/gavel_segmented_control.dart';

class TeamRoleFilter extends StatelessWidget {
  const TeamRoleFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => GavelSegmentedControl<String>(
    selected: selected,
    options: const {'Prosecution': 'Prosecution', 'Defense': 'Defense'},
    compactLabels: const {'Prosecution': 'Pros.', 'Defense': 'Def.'},
    keyFor: (side) => ValueKey('team_filter_$side'),
    onChanged: onChanged,
  );
}
