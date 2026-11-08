import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import 'exam_question.dart';
import 'timing_rule.dart';

enum ExamStatus {
  drafting('Drafting'),
  review('Ready for review'),
  rehearsal('Ready to rehearse');

  const ExamStatus(this.label);
  final String label;
}

@immutable
class ExamScript {
  ExamScript({
    required this.caseId,
    required this.witnessId,
    required this.phase,
    String goal = '',
    this.status = ExamStatus.drafting,
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
  final ExamStatus status;
  final List<ExamQuestion> questions;
  String get id => '$witnessId:${phase.name}';
  int get estimatedSeconds =>
      questions.fold(0, (total, q) => total + q.estimatedSeconds);
  factory ExamScript.fromMap(Map<String, Object?> map) => ExamScript(
    caseId: map['caseId']! as String,
    witnessId: map['witnessId']! as String,
    phase: TrialPhase.values.byName(map['phase']! as String),
    goal: map['goal']! as String,
    status: ExamStatus.values.byName(map['status'] as String? ?? 'drafting'),
    questions: (map['questions']! as List)
        .map((q) => ExamQuestion.fromMap(Map<String, Object?>.from(q as Map)))
        .toList(),
  );
  Map<String, Object?> toMap() => {
    'caseId': caseId,
    'witnessId': witnessId,
    'phase': phase.name,
    'goal': goal,
    'status': status.name,
    'questions': questions.map((q) => q.toMap()).toList(),
  };
  ExamScript copyWith({
    String? goal,
    List<ExamQuestion>? questions,
    ExamStatus? status,
  }) => ExamScript(
    caseId: caseId,
    witnessId: witnessId,
    phase: phase,
    goal: goal ?? this.goal,
    status:
        status ??
        ((goal != null && goal.trim() != this.goal) ||
                (questions != null && !listEquals(questions, this.questions))
            ? ExamStatus.drafting
            : this.status),
    questions: questions ?? this.questions,
  );
  @override
  bool operator ==(Object other) =>
      other is ExamScript &&
      caseId == other.caseId &&
      witnessId == other.witnessId &&
      phase == other.phase &&
      goal == other.goal &&
      status == other.status &&
      listEquals(questions, other.questions);
  @override
  int get hashCode => Object.hash(
    caseId,
    witnessId,
    phase,
    goal,
    status,
    Object.hashAll(questions),
  );
}
