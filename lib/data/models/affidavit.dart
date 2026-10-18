import 'package:flutter/foundation.dart';

@immutable
class Affidavit {
  const Affidavit({
    required this.id,
    required this.caseId,
    required this.witnessId,
    required this.title,
    required this.body,
  });

  factory Affidavit.fromMap(Map<String, Object?> map) => Affidavit(
    id: map['id']! as String,
    caseId: map['caseId']! as String,
    witnessId: map['witnessId']! as String,
    title: map['title']! as String,
    body: map['body']! as String,
  );

  final String id;
  final String caseId;
  final String witnessId;
  final String title;
  final String body;

  Affidavit copyWith({
    String? id,
    String? caseId,
    String? witnessId,
    String? title,
    String? body,
  }) => Affidavit(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    witnessId: witnessId ?? this.witnessId,
    title: title ?? this.title,
    body: body ?? this.body,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'caseId': caseId,
    'witnessId': witnessId,
    'title': title,
    'body': body,
  };

  @override
  bool operator ==(Object other) =>
      other is Affidavit &&
      other.id == id &&
      other.caseId == caseId &&
      other.witnessId == witnessId &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, caseId, witnessId, title, body);
}
