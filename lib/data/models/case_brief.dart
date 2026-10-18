import 'package:flutter/foundation.dart';

import 'trial_side.dart';

enum EvidenceKind { exhibit, affidavit }

@immutable
class EvidenceLink {
  const EvidenceLink({
    required this.kind,
    required this.sourceId,
    required this.note,
  });

  factory EvidenceLink.fromMap(Map<String, Object?> map) => EvidenceLink(
    kind: EvidenceKind.values.byName(map['kind']! as String),
    sourceId: map['sourceId']! as String,
    note: map['note']! as String,
  );

  final EvidenceKind kind;
  final String sourceId;

  /// Explains how the source supports or limits the fact.
  final String note;

  EvidenceLink copyWith({EvidenceKind? kind, String? sourceId, String? note}) =>
      EvidenceLink(
        kind: kind ?? this.kind,
        sourceId: sourceId ?? this.sourceId,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
    'kind': kind.name,
    'sourceId': sourceId,
    'note': note,
  };

  @override
  bool operator ==(Object other) =>
      other is EvidenceLink &&
      other.kind == kind &&
      other.sourceId == sourceId &&
      other.note == note;
  @override
  int get hashCode => Object.hash(kind, sourceId, note);
}

@immutable
class BriefFact {
  BriefFact({
    required this.id,
    required this.text,
    required List<EvidenceLink> evidence,
  }) : evidence = List.unmodifiable(evidence);

  factory BriefFact.fromMap(Map<String, Object?> map) => BriefFact(
    id: map['id']! as String,
    text: map['text']! as String,
    evidence: (map['evidence']! as List)
        .map((e) => EvidenceLink.fromMap(Map<String, Object?>.from(e as Map)))
        .toList(),
  );

  final String id;
  final String text;
  final List<EvidenceLink> evidence;

  BriefFact copyWith({
    String? id,
    String? text,
    List<EvidenceLink>? evidence,
  }) => BriefFact(
    id: id ?? this.id,
    text: text ?? this.text,
    evidence: evidence ?? this.evidence,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'text': text,
    'evidence': evidence.map((e) => e.toMap()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is BriefFact &&
      other.id == id &&
      other.text == text &&
      listEquals(other.evidence, evidence);
  @override
  int get hashCode => Object.hash(id, text, Object.hashAll(evidence));
}

@immutable
class BriefArgument {
  const BriefArgument({
    required this.id,
    required this.side,
    required this.argument,
    required this.counter,
  });

  factory BriefArgument.fromMap(Map<String, Object?> map) => BriefArgument(
    id: map['id']! as String,
    side: TrialSide.values.byName(map['side']! as String),
    argument: map['argument']! as String,
    counter: map['counter']! as String,
  );

  final String id;

  /// The side making the anticipated argument; the counter is for the other side.
  final TrialSide side;
  final String argument;
  final String counter;

  BriefArgument copyWith({
    String? id,
    TrialSide? side,
    String? argument,
    String? counter,
  }) => BriefArgument(
    id: id ?? this.id,
    side: side ?? this.side,
    argument: argument ?? this.argument,
    counter: counter ?? this.counter,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'side': side.name,
    'argument': argument,
    'counter': counter,
  };

  @override
  bool operator ==(Object other) =>
      other is BriefArgument &&
      other.id == id &&
      other.side == side &&
      other.argument == argument &&
      other.counter == counter;
  @override
  int get hashCode => Object.hash(id, side, argument, counter);
}

@immutable
class CaseBrief {
  CaseBrief({
    required this.caseId,
    required List<BriefFact> facts,
    required List<BriefArgument> arguments,
  }) : facts = List.unmodifiable(facts),
       arguments = List.unmodifiable(arguments);

  factory CaseBrief.fromMap(Map<String, Object?> map) => CaseBrief(
    caseId: map['caseId']! as String,
    facts: (map['facts']! as List)
        .map((f) => BriefFact.fromMap(Map<String, Object?>.from(f as Map)))
        .toList(),
    arguments: (map['arguments']! as List)
        .map((a) => BriefArgument.fromMap(Map<String, Object?>.from(a as Map)))
        .toList(),
  );

  final String caseId;
  final List<BriefFact> facts;
  final List<BriefArgument> arguments;

  CaseBrief copyWith({
    String? caseId,
    List<BriefFact>? facts,
    List<BriefArgument>? arguments,
  }) => CaseBrief(
    caseId: caseId ?? this.caseId,
    facts: facts ?? this.facts,
    arguments: arguments ?? this.arguments,
  );

  Map<String, Object?> toMap() => {
    'caseId': caseId,
    'facts': facts.map((f) => f.toMap()).toList(),
    'arguments': arguments.map((a) => a.toMap()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is CaseBrief &&
      other.caseId == caseId &&
      listEquals(other.facts, facts) &&
      listEquals(other.arguments, arguments);
  @override
  int get hashCode =>
      Object.hash(caseId, Object.hashAll(facts), Object.hashAll(arguments));
}
