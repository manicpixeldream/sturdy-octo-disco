import 'package:flutter/foundation.dart';

enum TrialPhase {
  opening('Opening statement'),
  direct('Direct examination'),
  cross('Cross examination'),
  closing('Closing argument');

  const TrialPhase(this.label);
  final String label;
}

@immutable
class TimingRule {
  const TimingRule({
    required this.id,
    required this.caseId,
    required this.phase,
    required this.minutes,
    this.sharedAcrossWitnesses = false,
  }) : assert(minutes > 0);

  factory TimingRule.fromMap(Map<String, Object?> map) => TimingRule(
    id: map['id']! as String,
    caseId: map['caseId']! as String,
    phase: TrialPhase.values.byName(map['phase']! as String),
    minutes: map['minutes']! as int,
    sharedAcrossWitnesses: map['sharedAcrossWitnesses']! as bool,
  );

  final String id;
  final String caseId;
  final TrialPhase phase;
  final int minutes;
  final bool sharedAcrossWitnesses;

  TimingRule copyWith({
    String? id,
    String? caseId,
    TrialPhase? phase,
    int? minutes,
    bool? sharedAcrossWitnesses,
  }) => TimingRule(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    phase: phase ?? this.phase,
    minutes: minutes ?? this.minutes,
    sharedAcrossWitnesses: sharedAcrossWitnesses ?? this.sharedAcrossWitnesses,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'caseId': caseId,
    'phase': phase.name,
    'minutes': minutes,
    'sharedAcrossWitnesses': sharedAcrossWitnesses,
  };

  @override
  bool operator ==(Object other) =>
      other is TimingRule &&
      other.id == id &&
      other.caseId == caseId &&
      other.phase == phase &&
      other.minutes == minutes &&
      other.sharedAcrossWitnesses == sharedAcrossWitnesses;

  @override
  int get hashCode =>
      Object.hash(id, caseId, phase, minutes, sharedAcrossWitnesses);
}
