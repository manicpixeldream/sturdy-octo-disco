import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';
import '../../../data/models/teammate.dart';

class PracticeFollowUpDialog extends StatefulWidget {
  const PracticeFollowUpDialog({
    super.key,
    required this.teammates,
    required this.currentTeammateId,
  });

  final List<Teammate> teammates;
  final String currentTeammateId;

  @override
  State<PracticeFollowUpDialog> createState() => _PracticeFollowUpDialogState();
}

class _PracticeFollowUpDialogState extends State<PracticeFollowUpDialog> {
  final _title = TextEditingController();
  late String _assigneeId = widget.teammates
      .firstWhere(
        (teammate) => teammate.id == widget.currentTeammateId,
        orElse: () => widget.teammates.first,
      )
      .id;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Practice follow-up'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('practice_follow_up_title'),
            controller: _title,
            autofocus: true,
            maxLength: 160,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'What needs doing?'),
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            initialValue: _assigneeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Assign to'),
            items: [
              for (final teammate in widget.teammates)
                DropdownMenuItem(
                  value: teammate.id,
                  child: Text(teammate.name),
                ),
            ],
            onChanged: (id) => setState(() => _assigneeId = id!),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('practice_follow_up_submit'),
        onPressed: _title.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, (
                title: _title.text,
                assigneeId: _assigneeId,
              )),
        child: const Text('Assign task'),
      ),
    ],
  );
}
