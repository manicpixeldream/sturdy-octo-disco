import 'package:flutter/foundation.dart';

enum ResearchRole { user, assistant }

@immutable
class ResearchAnswerPoint {
  ResearchAnswerPoint({required this.text, required List<String> sourceIds})
    : sourceIds = List.unmodifiable(sourceIds);
  factory ResearchAnswerPoint.fromMap(Map<String, Object?> map) =>
      ResearchAnswerPoint(
        text: map['text']! as String,
        sourceIds: List<String>.from(map['sourceIds']! as List),
      );
  final String text;
  final List<String> sourceIds;
  ResearchAnswerPoint copyWith({String? text, List<String>? sourceIds}) =>
      ResearchAnswerPoint(
        text: text ?? this.text,
        sourceIds: sourceIds ?? this.sourceIds,
      );
  Map<String, Object?> toMap() => {'text': text, 'sourceIds': sourceIds};
  @override
  bool operator ==(Object other) =>
      other is ResearchAnswerPoint &&
      other.text == text &&
      listEquals(other.sourceIds, sourceIds);
  @override
  int get hashCode => Object.hash(text, Object.hashAll(sourceIds));
}

@immutable
class ResearchMessage {
  ResearchMessage({
    required this.id,
    required this.role,
    required this.text,
    List<ResearchAnswerPoint> points = const [],
  }) : points = List.unmodifiable(points);
  factory ResearchMessage.fromMap(Map<String, Object?> map) => ResearchMessage(
    id: map['id']! as String,
    role: ResearchRole.values.byName(map['role']! as String),
    text: map['text']! as String,
    points: (map['points']! as List)
        .map(
          (p) =>
              ResearchAnswerPoint.fromMap(Map<String, Object?>.from(p as Map)),
        )
        .toList(),
  );
  final String id;
  final ResearchRole role;
  final String text;
  final List<ResearchAnswerPoint> points;
  ResearchMessage copyWith({String? text, List<ResearchAnswerPoint>? points}) =>
      ResearchMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        points: points ?? this.points,
      );
  Map<String, Object?> toMap() => {
    'id': id,
    'role': role.name,
    'text': text,
    'points': points.map((p) => p.toMap()).toList(),
  };
  @override
  bool operator ==(Object other) =>
      other is ResearchMessage &&
      other.id == id &&
      other.role == role &&
      other.text == text &&
      listEquals(other.points, points);
  @override
  int get hashCode => Object.hash(id, role, text, Object.hashAll(points));
}

@immutable
class ResearchReply {
  ResearchReply({
    required this.title,
    required List<ResearchAnswerPoint> points,
  }) : points = List.unmodifiable(points);
  factory ResearchReply.fromMap(Map<String, Object?> map) => ResearchReply(
    title: map['title']! as String,
    points: (map['points']! as List)
        .map(
          (p) =>
              ResearchAnswerPoint.fromMap(Map<String, Object?>.from(p as Map)),
        )
        .toList(),
  );
  final String title;
  final List<ResearchAnswerPoint> points;
  ResearchReply copyWith({String? title, List<ResearchAnswerPoint>? points}) =>
      ResearchReply(title: title ?? this.title, points: points ?? this.points);
  Map<String, Object?> toMap() => {
    'title': title,
    'points': points.map((p) => p.toMap()).toList(),
  };
  @override
  bool operator ==(Object other) =>
      other is ResearchReply &&
      other.title == title &&
      listEquals(other.points, points);
  @override
  int get hashCode => Object.hash(title, Object.hashAll(points));
}
