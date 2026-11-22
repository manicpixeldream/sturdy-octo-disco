import 'package:flutter/foundation.dart';

@immutable
class Teammate {
  const Teammate({required this.id, required this.name, this.teamRole});

  factory Teammate.fromMap(Map<String, Object?> map) => Teammate(
    id: map['id']! as String,
    name: map['name']! as String,
    teamRole: map['teamRole'] as String?,
  );

  final String id;
  final String name;
  final String? teamRole;

  bool get canAssignRoles => teamRole == 'captain' || teamRole == 'coach';

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Teammate copyWith({String? id, String? name, String? teamRole}) => Teammate(
    id: id ?? this.id,
    name: name ?? this.name,
    teamRole: teamRole ?? this.teamRole,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    if (teamRole != null) 'teamRole': teamRole,
  };

  @override
  bool operator ==(Object other) =>
      other is Teammate &&
      other.id == id &&
      other.name == name &&
      other.teamRole == teamRole;

  @override
  int get hashCode => Object.hash(id, name, teamRole);
}
