import 'package:flutter/foundation.dart';

@immutable
class PracticeSession {
  PracticeSession({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.durationMinutes,
    required this.location,
    required List<String> participantIds,
  }) : participantIds = List.unmodifiable(participantIds) {
    if (durationMinutes <= 0) {
      throw ArgumentError.value(durationMinutes, 'durationMinutes');
    }
  }
  final String id, title, location;
  final DateTime startsAt;
  final int durationMinutes;
  final List<String> participantIds;
  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));
  factory PracticeSession.fromMap(Map<String, Object?> map) => PracticeSession(
    id: map['id']! as String,
    title: map['title']! as String,
    location: map['location']! as String,
    startsAt: DateTime.parse(map['startsAt']! as String),
    durationMinutes: map['durationMinutes']! as int,
    participantIds: (map['participantIds']! as List).cast<String>(),
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'location': location,
    'startsAt': startsAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'participantIds': participantIds,
  };
  PracticeSession copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? startsAt,
    int? durationMinutes,
    List<String>? participantIds,
  }) => PracticeSession(
    id: id ?? this.id,
    title: title ?? this.title,
    location: location ?? this.location,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    participantIds: participantIds ?? this.participantIds,
  );
  @override
  bool operator ==(Object other) =>
      other is PracticeSession &&
      id == other.id &&
      title == other.title &&
      location == other.location &&
      startsAt == other.startsAt &&
      durationMinutes == other.durationMinutes &&
      listEquals(participantIds, other.participantIds);
  @override
  int get hashCode => Object.hash(
    id,
    title,
    location,
    startsAt,
    durationMinutes,
    Object.hashAll(participantIds),
  );
}
