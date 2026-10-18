import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';

class CasePage extends StatelessWidget {
  const CasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case')),
      body: const Center(
        child: EmptyState(
          icon: Icons.folder_outlined,
          title: 'Case',
          message: 'Case brief, exhibits, and rules. Coming in v0.5.',
        ),
      ),
    );
  }
}
