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
    required this.onSave,
  });

  final List<Teammate> teammates;
  final String currentTeammateId;
  final DateTime today, initialDueDate;
  final Future<bool> Function(String title, String assigneeId, DateTime dueDate)
  onSave;

  @override
  State<PracticeFollowUpDialog> createState() => _PracticeFollowUpDialogState();
}

class _PracticeFollowUpDialogState extends State<PracticeFollowUpDialog> {
  final _title = TextEditingController();
  bool _saving = false;
  bool _failed = false;
  late DateTime _dueDate = widget.initialDueDate;
  late String _assigneeId = widget.teammates
      .firstWhere(
        (teammate) => teammate.id == widget.currentTeammateId,
        orElse: () => widget.teammates.first,
      )
      .id;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await widget.onSave(_title.text, _assigneeId, _dueDate);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

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
            enabled: !_saving,
            maxLength: 160,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Task title'),
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
            onChanged: _saving
                ? null
                : (id) => setState(() => _assigneeId = id!),
          ),
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            key: const ValueKey('practice_follow_up_due'),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Due ${DateFormat.yMMMd().format(_dueDate)}'),
            onPressed: _saving
                ? null
                : () async {
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
          if (_failed)
            const Text('Could not assign the task. Your draft is still here.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('practice_follow_up_submit'),
        onPressed: _saving || _title.text.trim().isEmpty ? null : _save,
        child: Text(_saving ? 'Assigning…' : 'Assign task'),
      ),
    ],
  );
}
