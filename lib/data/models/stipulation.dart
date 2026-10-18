import 'package:flutter/foundation.dart';

@immutable
class Stipulation {
  const Stipulation({
    required this.id,
    required this.caseId,
    required this.number,
    required this.text,
  });

  factory Stipulation.fromMap(Map<String, Object?> map) => Stipulation(
    id: map['id']! as String,
    caseId: map['caseId']! as String,
    number: map['number']! as int,
    text: map['text']! as String,
  );

  final String id;
  final String caseId;
  final int number;
  final String text;

  Stipulation copyWith({
    String? id,
    String? caseId,
    int? number,
    String? text,
  }) => Stipulation(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    number: number ?? this.number,
    text: text ?? this.text,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'caseId': caseId,
    'number': number,
    'text': text,
  };

  @override
  bool operator ==(Object other) =>
      other is Stipulation &&
      other.id == id &&
      other.caseId == caseId &&
      other.number == number &&
      other.text == text;

  @override
  int get hashCode => Object.hash(id, caseId, number, text);
}
