import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';

class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Research')),
      body: const Center(
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'Research',
          message: 'Ask the case and build your library. Coming in v0.6.',
        ),
      ),
    );
  }
}
