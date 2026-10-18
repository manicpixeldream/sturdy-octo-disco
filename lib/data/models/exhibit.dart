import 'package:flutter/foundation.dart';

@immutable
class Exhibit {
  const Exhibit({
    required this.id,
    required this.caseId,
    required this.number,
    required this.title,
    required this.description,
  });

  factory Exhibit.fromMap(Map<String, Object?> map) => Exhibit(
    id: map['id']! as String,
    caseId: map['caseId']! as String,
    number: map['number']! as int,
    title: map['title']! as String,
    description: map['description']! as String,
  );

  final String id;
  final String caseId;
  final int number;
  final String title;
  final String description;

  String get label => 'Ex. $number';

  Exhibit copyWith({
    String? id,
    String? caseId,
    int? number,
    String? title,
    String? description,
  }) => Exhibit(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    number: number ?? this.number,
    title: title ?? this.title,
    description: description ?? this.description,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'caseId': caseId,
    'number': number,
    'title': title,
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      other is Exhibit &&
      other.id == id &&
      other.caseId == caseId &&
      other.number == number &&
      other.title == title &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, caseId, number, title, description);
}
