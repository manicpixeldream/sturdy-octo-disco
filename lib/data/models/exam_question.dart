import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

@immutable
class ExamQuestion {
  ExamQuestion({
    required this.id,
    required String text,
    this.estimatedSeconds = 45,
    List<String> exhibitIds = const [],
    List<String> sourceIds = const [],
    this.flagged = false,
  }) : text = text.trim(),
       exhibitIds = List.unmodifiable(exhibitIds),
       sourceIds = List.unmodifiable(sourceIds) {
    if (id.isEmpty ||
        this.text.isEmpty ||
        this.text.characters.length > 2000 ||
        estimatedSeconds < 1 ||
        estimatedSeconds > 3600 ||
        exhibitIds.toSet().length != exhibitIds.length) {
      throw ArgumentError('Invalid examination question');
    }
  }
  final String id, text;
  final int estimatedSeconds;
  final List<String> exhibitIds, sourceIds;
  final bool flagged;
  factory ExamQuestion.fromMap(Map<String, Object?> map) => ExamQuestion(
    id: map['id']! as String,
    text: map['text']! as String,
    estimatedSeconds: map['estimatedSeconds']! as int,
    exhibitIds: (map['exhibitIds']! as List).cast<String>(),
    flagged: map['flagged']! as bool,
    sourceIds: (map['sourceIds'] as List?)?.cast<String>() ?? const [],
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'text': text,
    'estimatedSeconds': estimatedSeconds,
    'exhibitIds': exhibitIds,
    'flagged': flagged,
    if (sourceIds.isNotEmpty) 'sourceIds': sourceIds,
  };
  ExamQuestion copyWith({
    String? text,
    int? estimatedSeconds,
    List<String>? exhibitIds,
    List<String>? sourceIds,
    bool? flagged,
  }) => ExamQuestion(
    id: id,
    text: text ?? this.text,
    estimatedSeconds: estimatedSeconds ?? this.estimatedSeconds,
    exhibitIds: exhibitIds ?? this.exhibitIds,
    sourceIds: sourceIds ?? this.sourceIds,
    flagged: flagged ?? this.flagged,
  );
  @override
  bool operator ==(Object other) =>
      other is ExamQuestion &&
      id == other.id &&
      text == other.text &&
      estimatedSeconds == other.estimatedSeconds &&
      flagged == other.flagged &&
      listEquals(exhibitIds, other.exhibitIds) &&
      listEquals(sourceIds, other.sourceIds);
  @override
  int get hashCode => Object.hash(
    id,
    text,
    estimatedSeconds,
    flagged,
    Object.hashAll(exhibitIds),
    Object.hashAll(sourceIds),
  );
}
