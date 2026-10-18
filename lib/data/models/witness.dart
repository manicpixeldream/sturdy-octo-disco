import 'package:flutter/foundation.dart';

import 'trial_side.dart';

@immutable
class Witness {
  const Witness({
    required this.id,
    required this.caseId,
    required this.name,
    required this.side,
    required this.description,
  });

  factory Witness.fromMap(Map<String, Object?> map) => Witness(
    id: map['id']! as String,
    caseId: map['caseId']! as String,
    name: map['name']! as String,
    side: TrialSide.values.byName(map['side']! as String),
    description: map['description']! as String,
  );

  final String id;
  final String caseId;
  final String name;
  final TrialSide side;
  final String description;

  Witness copyWith({
    String? id,
    String? caseId,
    String? name,
    TrialSide? side,
    String? description,
  }) => Witness(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    name: name ?? this.name,
    side: side ?? this.side,
    description: description ?? this.description,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'caseId': caseId,
    'name': name,
    'side': side.name,
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      other is Witness &&
      other.id == id &&
      other.caseId == caseId &&
      other.name == name &&
      other.side == side &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, caseId, name, side, description);
}
