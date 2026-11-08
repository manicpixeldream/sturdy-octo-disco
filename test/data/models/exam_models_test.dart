import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/exam_question.dart';
import 'package:gavel/data/models/exam_script.dart';
import 'package:gavel/data/models/timing_rule.dart';

void main() {
  test('models own immutable collections and survive JSON roundtrip', () {
    final ids = ['ex_1'];
    final q = ExamQuestion(
      id: 'q',
      text: '  What happened?  ',
      exhibitIds: ids,
      flagged: true,
    );
    ids.clear();
    expect(q.exhibitIds, ['ex_1']);
    expect(q.text, 'What happened?');
    final questions = [q];
    final script = ExamScript(
      caseId: 'case',
      witnessId: 'w',
      phase: TrialPhase.direct,
      goal: ' Establish observations ',
      questions: questions,
    );
    questions.clear();
    expect(script.questions.length, 1);
    expect(
      ExamScript.fromMap(
        Map<String, Object?>.from(
          jsonDecode(jsonEncode(script.toMap())) as Map,
        ),
      ),
      script,
    );
    expect(script.estimatedSeconds, 45);
    expect(script.copyWith(goal: 'New goal').questions, [q]);
    expect(q.copyWith(estimatedSeconds: 60).estimatedSeconds, 60);
    expect(() => script.questions.clear(), throwsUnsupportedError);
    expect(() => q.exhibitIds.clear(), throwsUnsupportedError);
  });
  test('invalid drafts and phases are rejected', () {
    expect(() => ExamQuestion(id: 'q', text: ' '), throwsArgumentError);
    expect(
      () => ExamQuestion(id: 'q', text: 'Question', estimatedSeconds: 0),
      throwsArgumentError,
    );
    expect(
      () => ExamQuestion(id: 'q', text: 'Question', exhibitIds: ['x', 'x']),
      throwsArgumentError,
    );
    expect(
      () => ExamScript(caseId: 'c', witnessId: 'w', phase: TrialPhase.opening),
      throwsArgumentError,
    );
    final q = ExamQuestion(id: 'q', text: 'Question');
    expect(
      () => ExamScript(
        caseId: 'c',
        witnessId: 'w',
        phase: TrialPhase.cross,
        questions: [q, q],
      ),
      throwsArgumentError,
    );
  });
}
