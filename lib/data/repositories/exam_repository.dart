import '../models/exam_script.dart';

abstract interface class ExamRepository {
  Future<List<ExamScript>> fetchScripts(String caseId);

  /// Save the complete script atomically; failure must leave the prior value.
  Future<void> saveScript(ExamScript script);
}
