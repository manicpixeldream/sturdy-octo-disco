import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.onAsk, this.enabled = true});
  static const suggestions = [
    'Build the case timeline',
    'What limits the eyewitness identification?',
    'Compare the fire experts',
    'Explain relevance and motive',
  ];
  final ValueChanged<String> onAsk;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Spacing.sm,
    runSpacing: Spacing.sm,
    children: [
      for (final (index, text) in suggestions.indexed)
        OutlinedButton(
          key: ValueKey('research_suggestion_$index'),
          onPressed: enabled ? () => onAsk(text) : null,
          child: Text(text),
        ),
    ],
  );
}
