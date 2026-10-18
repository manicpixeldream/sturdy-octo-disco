import 'package:flutter/foundation.dart';

import 'case_brief.dart';

enum ResearchSourceKind {
  precedent('Precedents'),
  definition('Definitions'),
  article('Articles'),
  caseMaterial('Case materials');

  const ResearchSourceKind(this.label);
  final String label;
}

@immutable
class ResearchSource {
  const ResearchSource({
    required this.id,
    required this.title,
    required this.kind,
    required this.citation,
    required this.content,
    required this.context,
    this.caseId,
    this.url,
    this.evidenceKind,
  });

  factory ResearchSource.fromMap(Map<String, Object?> map) => ResearchSource(
    id: map['id']! as String,
    title: map['title']! as String,
    kind: ResearchSourceKind.values.byName(map['kind']! as String),
    citation: map['citation']! as String,
    content: map['content']! as String,
    context: map['context']! as String,
    caseId: map['caseId'] as String?,
    url: map['url'] as String?,
    evidenceKind: map['evidenceKind'] == null
        ? null
        : EvidenceKind.values.byName(map['evidenceKind']! as String),
  );

  final String id;
  final String title;
  final ResearchSourceKind kind;
  final String citation;
  final String content;

  /// Identifies jurisdiction, historical scope, or fictional packet provenance.
  final String context;
  final String? caseId;
  final String? url;
  final EvidenceKind? evidenceKind;

  ResearchSource copyWith({
    String? title,
    String? citation,
    String? content,
    String? context,
  }) => ResearchSource(
    id: id,
    title: title ?? this.title,
    kind: kind,
    citation: citation ?? this.citation,
    content: content ?? this.content,
    context: context ?? this.context,
    caseId: caseId,
    url: url,
    evidenceKind: evidenceKind,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'citation': citation,
    'content': content,
    'context': context,
    'caseId': caseId,
    'url': url,
    'evidenceKind': evidenceKind?.name,
  };

  @override
  bool operator ==(Object other) =>
      other is ResearchSource &&
      other.id == id &&
      other.title == title &&
      other.kind == kind &&
      other.citation == citation &&
      other.content == content &&
      other.context == context &&
      other.caseId == caseId &&
      other.url == url &&
      other.evidenceKind == evidenceKind;
  @override
  int get hashCode => Object.hash(
    id,
    title,
    kind,
    citation,
    content,
    context,
    caseId,
    url,
    evidenceKind,
  );
}
