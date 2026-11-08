import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/data/mock/mock_exam_repository.dart';

void main() {
  test('atomic script replacement retains order and isolates cases', () async {
    final repo = MockExamRepository();
    final script = ExamScript(
      caseId: 'a',
      witnessId: 'w',
      phase: TrialPhase.direct,
      questions: [ExamQuestion(id: 'q', text: 'First')],
    );
    await repo.saveScript(script);
    await repo.saveScript(script.copyWith(goal: 'Edited'));
    expect((await repo.fetchScripts('a')).single.goal, 'Edited');
    expect(await repo.fetchScripts('b'), isEmpty);
    expect(() => (script.questions).clear(), throwsUnsupportedError);
    final fetched = await repo.fetchScripts('a');
    expect(() => fetched.clear(), throwsUnsupportedError);
  });
}
