import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/spacing.dart';
import '../../../data/models/exam_question.dart';
import '../../../data/models/exhibit.dart';

class QuestionEditorSheet extends StatefulWidget {
  const QuestionEditorSheet({
    super.key,
    required this.questionId,
    required this.exhibits,
    required this.sourceLabel,
    required this.onSave,
    this.initial,
  });
  final String questionId;
  final List<Exhibit> exhibits;
  final String Function(String) sourceLabel;
  final ExamQuestion? initial;
  final Future<bool> Function(ExamQuestion) onSave;
  @override
  State<QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<QuestionEditorSheet> {
  final _form = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.initial?.text ?? '');
  late final _seconds = TextEditingController(
    text: '${widget.initial?.estimatedSeconds ?? 45}',
  );
  late final Set<String> _exhibits = {...?widget.initial?.exhibitIds};
  late final _sources = {...?widget.initial?.sourceIds};
  late bool _flagged = widget.initial?.flagged ?? false;
  bool _saving = false, _failed = false;
  @override
  void dispose() {
    _text.dispose();
    _seconds.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await widget.onSave(
      ExamQuestion(
        id: widget.questionId,
        text: _text.text,
        estimatedSeconds: int.parse(_seconds.text),
        exhibitIds: _exhibits.toList(),
        sourceIds: _sources.toList(),
        flagged: _flagged,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initial == null ? 'Add question' : 'Edit question',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.lg),
                TextFormField(
                  key: const ValueKey('question_text'),
                  controller: _text,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a question.'
                      : null,
                ),
                const SizedBox(height: Spacing.md),
                TextFormField(
                  key: const ValueKey('question_seconds'),
                  controller: _seconds,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Estimated seconds',
                    helperText: 'Include the question and expected answer.',
                  ),
                  validator: (value) {
                    final seconds = int.tryParse(value ?? '');
                    return seconds == null || seconds < 1 || seconds > 3600
                        ? 'Enter 1–3600 seconds.'
                        : null;
                  },
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Link exhibits',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'A link records script usage; it does not establish admissibility.',
                ),
                const SizedBox(height: Spacing.sm),
                if (widget.exhibits.isEmpty)
                  const Text('No exhibits available.'),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final exhibit in widget.exhibits)
                      FilterChip(
                        key: ValueKey('question_exhibit_${exhibit.id}'),
                        label: Text(exhibit.label),
                        tooltip: exhibit.title,
                        selected: _exhibits.contains(exhibit.id),
                        onSelected: _saving
                            ? null
                            : (selected) => setState(() {
                                if (selected) {
                                  _exhibits.add(exhibit.id);
                                } else {
                                  _exhibits.remove(exhibit.id);
                                }
                              }),
                      ),
                  ],
                ),
                for (final id in _exhibits.where(
                  (id) => !widget.exhibits.any((exhibit) => exhibit.id == id),
                ))
                  InputChip(
                    label: Text('Unavailable exhibit: $id'),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _exhibits.remove(id)),
                  ),
                if (_sources.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  const Text('Attached research sources'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final id in _sources)
                        InputChip(
                          key: ValueKey('question_source_$id'),
                          label: Text(widget.sourceLabel(id)),
                          deleteButtonTooltipMessage:
                              'Remove ${widget.sourceLabel(id)}',
                          onDeleted: _saving
                              ? null
                              : () => setState(() => _sources.remove(id)),
                        ),
                    ],
                  ),
                ],
                CheckboxListTile(
                  key: const ValueKey('question_flagged'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Flag for review'),
                  value: _flagged,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _flagged = value!),
                ),
                if (_failed)
                  const Text(
                    'Could not save. Your draft is still here; try again.',
                    key: ValueKey('question_save_error'),
                  ),
                const SizedBox(height: Spacing.lg),
                Wrap(
                  spacing: Spacing.md,
                  runSpacing: Spacing.sm,
                  children: [
                    TextButton(
                      key: const ValueKey('question_cancel'),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      key: const ValueKey('question_save'),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save question'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
