import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spacing.dart';
import '../../../data/models/teammate.dart';

class PracticeFollowUpDialog extends StatefulWidget {
  const PracticeFollowUpDialog({
    super.key,
    required this.teammates,
    required this.currentTeammateId,
    required this.today,
    required this.initialDueDate,
  });

  final List<Teammate> teammates;
  final String currentTeammateId;
  final DateTime today, initialDueDate;

  @override
  State<PracticeFollowUpDialog> createState() => _PracticeFollowUpDialogState();
}

class _PracticeFollowUpDialogState extends State<PracticeFollowUpDialog> {
  final _title = TextEditingController();
  late DateTime _dueDate = widget.initialDueDate;
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
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            key: const ValueKey('practice_follow_up_due'),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Due ${DateFormat.yMMMd().format(_dueDate)}'),
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: widget.today,
                lastDate: DateTime(widget.initialDueDate.year + 5),
              );
              if (mounted && selected != null) {
                setState(() => _dueDate = selected);
              }
            },
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
                dueDate: _dueDate,
              )),
        child: const Text('Assign task'),
      ),
    ],
  );
}
