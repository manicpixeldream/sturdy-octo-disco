import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';

class GoalEditorSheet extends StatefulWidget {
  const GoalEditorSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });
  final String initial;
  final Future<bool> Function(String) onSave;
  @override
  State<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<GoalEditorSheet> {
  late final _text = TextEditingController(text: widget.initial);
  bool _saving = false, _failed = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + Spacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examination goal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              key: const ValueKey('exam_goal_text'),
              controller: _text,
              enabled: !_saving,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'What should this examination establish?',
              ),
            ),
            if (_failed) const Text('Could not save your goal. Try again.'),
            Wrap(
              spacing: Spacing.md,
              children: [
                TextButton(
                  key: const ValueKey('exam_goal_cancel'),
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('exam_goal_save'),
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() {
                            _saving = true;
                            _failed = false;
                          });
                          final saved = await widget.onSave(_text.text.trim());
                          if (!context.mounted) return;
                          if (saved) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() {
                              _saving = false;
                              _failed = true;
                            });
                          }
                        },
                  child: Text(_saving ? 'Saving…' : 'Save goal'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
