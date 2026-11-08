import 'package:flutter/foundation.dart';

@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.dueDate,
    this.isDone = false,
    this.workRoute,
  });

  factory TaskItem.fromMap(Map<String, Object?> map) => TaskItem(
    id: map['id']! as String,
    title: map['title']! as String,
    assigneeId: map['assigneeId']! as String,
    dueDate: DateTime.parse(map['dueDate']! as String),
    isDone: map['isDone']! as bool,
    workRoute: map['workRoute'] as String?,
  );

  final String id;
  final String title;
  final String assigneeId;
  final DateTime dueDate;
  final bool isDone;
  final String? workRoute;

  TaskItem copyWith({
    String? id,
    String? title,
    String? assigneeId,
    DateTime? dueDate,
    bool? isDone,
  }) => TaskItem(
    id: id ?? this.id,
    title: title ?? this.title,
    assigneeId: assigneeId ?? this.assigneeId,
    dueDate: dueDate ?? this.dueDate,
    isDone: isDone ?? this.isDone,
    workRoute: workRoute,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'assigneeId': assigneeId,
    'dueDate': dueDate.toIso8601String(),
    'isDone': isDone,
    if (workRoute != null) 'workRoute': workRoute,
  };

  @override
  bool operator ==(Object other) =>
      other is TaskItem &&
      other.id == id &&
      other.title == title &&
      other.assigneeId == assigneeId &&
      other.dueDate == dueDate &&
      other.isDone == isDone &&
      other.workRoute == workRoute;

  @override
  int get hashCode =>
      Object.hash(id, title, assigneeId, dueDate, isDone, workRoute);
}
