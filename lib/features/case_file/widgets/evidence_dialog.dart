import 'package:material_ui/material_ui.dart';

import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';

class EvidenceDialog extends StatelessWidget {
  const EvidenceDialog({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: GavelKeys.caseEvidenceDialog,
    scrollable: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.sheet),
    ),
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    title: Text(title),
    content: SizedBox(
      width: 520,
      child: SelectableText(body, style: Theme.of(context).textTheme.bodyLarge),
    ),
    actions: [
      TextButton(
        key: GavelKeys.caseEvidenceClose,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back to brief'),
      ),
    ],
  );
}
