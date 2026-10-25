import 'package:flutter/foundation.dart';

import 'task_item.dart';

@immutable
class RoleAssignment {
  RoleAssignment({
    required this.roleId,
    required this.teammateId,
    required List<TaskItem> tasks,
  }) : tasks = List.unmodifiable(tasks);
  factory RoleAssignment.fromMap(Map<String, Object?> map) => RoleAssignment(
    roleId: map['roleId']! as String,
    teammateId: map['teammateId']! as String,
    tasks: (map['tasks']! as List)
        .map((t) => TaskItem.fromMap(Map<String, Object?>.from(t as Map)))
        .toList(),
  );
  Map<String, Object?> toMap() => {
    'roleId': roleId,
    'teammateId': teammateId,
    'tasks': tasks.map((t) => t.toMap()).toList(),
  };
  RoleAssignment copyWith({
    String? roleId,
    String? teammateId,
    List<TaskItem>? tasks,
  }) => RoleAssignment(
    roleId: roleId ?? this.roleId,
    teammateId: teammateId ?? this.teammateId,
    tasks: tasks ?? this.tasks,
  );
  @override
  bool operator ==(Object other) =>
      other is RoleAssignment &&
      roleId == other.roleId &&
      teammateId == other.teammateId &&
      listEquals(tasks, other.tasks);
  @override
  int get hashCode => Object.hash(roleId, teammateId, Object.hashAll(tasks));
  final String roleId, teammateId;
  final List<TaskItem> tasks;
}
