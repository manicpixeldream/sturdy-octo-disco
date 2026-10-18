import 'package:flutter/foundation.dart';

@immutable
class CaseFile {
  const CaseFile({
    required this.id,
    required this.title,
    required this.summary,
    required this.trialDate,
  });

  factory CaseFile.fromMap(Map<String, Object?> map) => CaseFile(
    id: map['id']! as String,
    title: map['title']! as String,
    summary: map['summary']! as String,
    trialDate: DateTime.parse(map['trialDate']! as String),
  );

  final String id;
  final String title;
  final String summary;
  final DateTime trialDate;

  CaseFile copyWith({
    String? id,
    String? title,
    String? summary,
    DateTime? trialDate,
  }) => CaseFile(
    id: id ?? this.id,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    trialDate: trialDate ?? this.trialDate,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'summary': summary,
    'trialDate': trialDate.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is CaseFile &&
      other.id == id &&
      other.title == title &&
      other.summary == summary &&
      other.trialDate == trialDate;

  @override
  int get hashCode => Object.hash(id, title, summary, trialDate);
}
