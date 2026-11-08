import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import 'exam_question.dart';
import 'timing_rule.dart';

@immutable
class ExamScript {
  ExamScript({
    required this.caseId,
    required this.witnessId,
    required this.phase,
    String goal = '',
    List<ExamQuestion> questions = const [],
  }) : goal = goal.trim(),
       questions = List.unmodifiable(questions) {
    if (caseId.isEmpty ||
        witnessId.isEmpty ||
        (phase != TrialPhase.direct && phase != TrialPhase.cross) ||
        this.goal.characters.length > 500 ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw ArgumentError('Invalid examination script');
    }
  }
  final String caseId, witnessId, goal;
  final TrialPhase phase;
  final List<ExamQuestion> questions;
  String get id => '$witnessId:${phase.name}';
  int get estimatedSeconds =>
      questions.fold(0, (total, q) => total + q.estimatedSeconds);
  factory ExamScript.fromMap(Map<String, Object?> map) => ExamScript(
    caseId: map['caseId']! as String,
    witnessId: map['witnessId']! as String,
    phase: TrialPhase.values.byName(map['phase']! as String),
    goal: map['goal']! as String,
    questions: (map['questions']! as List)
        .map((q) => ExamQuestion.fromMap(Map<String, Object?>.from(q as Map)))
        .toList(),
  );
  Map<String, Object?> toMap() => {
    'caseId': caseId,
    'witnessId': witnessId,
    'phase': phase.name,
    'goal': goal,
    'questions': questions.map((q) => q.toMap()).toList(),
  };
  ExamScript copyWith({String? goal, List<ExamQuestion>? questions}) =>
      ExamScript(
        caseId: caseId,
        witnessId: witnessId,
        phase: phase,
        goal: goal ?? this.goal,
        questions: questions ?? this.questions,
      );
  @override
  bool operator ==(Object other) =>
      other is ExamScript &&
      caseId == other.caseId &&
      witnessId == other.witnessId &&
      phase == other.phase &&
      goal == other.goal &&
      listEquals(questions, other.questions);
  @override
  int get hashCode =>
      Object.hash(caseId, witnessId, phase, goal, Object.hashAll(questions));
}
