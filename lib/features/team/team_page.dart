import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team')),
      body: const Center(
        child: EmptyState(
          icon: Icons.groups_outlined,
          title: 'Team',
          message: 'Roster, roles, and team chat. Coming in v0.7.',
        ),
      ),
    );
  }
}
