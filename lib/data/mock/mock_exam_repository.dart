import '../models/exam_script.dart';
import '../repositories/exam_repository.dart';

class MockExamRepository implements ExamRepository {
  MockExamRepository([List<ExamScript> scripts = const []])
    : _scripts = {for (final s in scripts) '${s.caseId}:${s.id}': s};
  final Map<String, ExamScript> _scripts;
  @override
  Future<List<ExamScript>> fetchScripts(String caseId) async =>
      List.unmodifiable(_scripts.values.where((s) => s.caseId == caseId));
  @override
  Future<void> saveScript(ExamScript script) async {
    _scripts['${script.caseId}:${script.id}'] = script;
  }
}
