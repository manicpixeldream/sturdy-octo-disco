import 'package:flutter/foundation.dart';

@immutable
class TrialRole {
  TrialRole({
    required this.id,
    required this.title,
    required this.side,
    required List<String> responsibilities,
    this.isWitness = false,
  }) : responsibilities = List.unmodifiable(responsibilities);
  factory TrialRole.fromMap(Map<String, Object?> map) => TrialRole(
    id: map['id']! as String,
    title: map['title']! as String,
    side: map['side']! as String,
    isWitness: map['isWitness']! as bool,
    responsibilities: (map['responsibilities']! as List).cast<String>(),
  );
  final String id, title, side;
  final List<String> responsibilities;
  final bool isWitness;
  TrialRole copyWith({
    String? id,
    String? title,
    String? side,
    List<String>? responsibilities,
    bool? isWitness,
  }) => TrialRole(
    id: id ?? this.id,
    title: title ?? this.title,
    side: side ?? this.side,
    responsibilities: responsibilities ?? this.responsibilities,
    isWitness: isWitness ?? this.isWitness,
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'side': side,
    'responsibilities': responsibilities,
    'isWitness': isWitness,
  };
  @override
  bool operator ==(Object other) =>
      other is TrialRole &&
      id == other.id &&
      title == other.title &&
      side == other.side &&
      isWitness == other.isWitness &&
      listEquals(responsibilities, other.responsibilities);
  @override
  int get hashCode =>
      Object.hash(id, title, side, isWitness, Object.hashAll(responsibilities));
}
