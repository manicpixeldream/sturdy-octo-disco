import 'package:flutter/foundation.dart';

enum CitationLocation { answer, caseBrief, examQuestion }

@immutable
class Citation {
  const Citation({
    required this.sourceId,
    required this.location,
    required this.referenceId,
    required this.label,
  });
  factory Citation.fromMap(Map<String, Object?> map) => Citation(
    sourceId: map['sourceId']! as String,
    location: CitationLocation.values.byName(map['location']! as String),
    referenceId: map['referenceId']! as String,
    label: map['label']! as String,
  );

  final String sourceId;
  final CitationLocation location;
  final String referenceId;
  final String label;
  String get id => '${location.name}:$referenceId:$sourceId';

  Citation copyWith({String? label}) => Citation(
    sourceId: sourceId,
    location: location,
    referenceId: referenceId,
    label: label ?? this.label,
  );
  Map<String, Object?> toMap() => {
    'sourceId': sourceId,
    'location': location.name,
    'referenceId': referenceId,
    'label': label,
  };
  @override
  bool operator ==(Object other) =>
      other is Citation &&
      other.sourceId == sourceId &&
      other.location == location &&
      other.referenceId == referenceId &&
      other.label == label;
  @override
  int get hashCode => Object.hash(sourceId, location, referenceId, label);
}
