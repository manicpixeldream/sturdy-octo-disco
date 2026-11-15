import '../../core/storage/workspace_storage.dart';

import '../models/exam_script.dart';
import '../repositories/exam_repository.dart';

class MockExamRepository implements ExamRepository {
  MockExamRepository([List<ExamScript> scripts = const [], this.storage])
    : _scripts = {
        for (final s in [
          ...scripts,
          ...?storage?.records('scripts', ExamScript.fromMap),
        ])
          '${s.caseId}:${s.id}': s,
      };
  final WorkspaceStorage? storage;
  final Map<String, ExamScript> _scripts;
  @override
  Future<List<ExamScript>> fetchScripts(String caseId) async =>
      List.unmodifiable(_scripts.values.where((s) => s.caseId == caseId));
  @override
  Future<void> saveScript(ExamScript script) async {
    final key = '${script.caseId}:${script.id}';
    _scripts[key] = script;
    storage?.putRecord('scripts', key, script.toMap());
  }
}
