import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

enum ChatMentionKind { task, exhibit }

@immutable
class ChatMention {
  const ChatMention({
    required this.kind,
    required this.itemId,
    required this.label,
  });
  final ChatMentionKind kind;
  final String itemId, label;
  String get id => '${kind.name}:$itemId';
  factory ChatMention.fromMap(Map<String, Object?> map) => ChatMention(
    kind: ChatMentionKind.values.byName(map['kind']! as String),
    itemId: map['itemId']! as String,
    label: map['label']! as String,
  );
  Map<String, Object?> toMap() => {
    'kind': kind.name,
    'itemId': itemId,
    'label': label,
  };
  @override
  bool operator ==(Object other) =>
      other is ChatMention &&
      kind == other.kind &&
      itemId == other.itemId &&
      label == other.label;
  @override
  int get hashCode => Object.hash(kind, itemId, label);
}

@immutable
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.caseId,
    required this.senderId,
    required String text,
    required this.createdAt,
    List<ChatMention> mentions = const [],
  }) : text = text.trim(),
       mentions = List.unmodifiable(mentions) {
    if (id.isEmpty ||
        caseId.isEmpty ||
        senderId.isEmpty ||
        this.text.characters.length > 2000 ||
        (this.text.isEmpty && mentions.isEmpty) ||
        mentions.length > 5 ||
        mentions.map((m) => m.id).toSet().length != mentions.length ||
        mentions.any((m) => m.itemId.isEmpty || m.label.trim().isEmpty)) {
      throw ArgumentError('Invalid chat message');
    }
  }
  final String id, caseId, senderId, text;
  final DateTime createdAt;
  final List<ChatMention> mentions;
  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
    id: map['id']! as String,
    caseId: map['caseId']! as String,
    senderId: map['senderId']! as String,
    text: map['text']! as String,
    createdAt: DateTime.parse(map['createdAt']! as String),
    mentions: (map['mentions']! as List)
        .map((m) => ChatMention.fromMap(Map<String, Object?>.from(m as Map)))
        .toList(),
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'caseId': caseId,
    'senderId': senderId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'mentions': mentions.map((m) => m.toMap()).toList(),
  };
  ChatMessage copyWith({String? text, List<ChatMention>? mentions}) =>
      ChatMessage(
        id: id,
        caseId: caseId,
        senderId: senderId,
        text: text ?? this.text,
        createdAt: createdAt,
        mentions: mentions ?? this.mentions,
      );
  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      id == other.id &&
      caseId == other.caseId &&
      senderId == other.senderId &&
      text == other.text &&
      createdAt == other.createdAt &&
      listEquals(mentions, other.mentions);
  @override
  int get hashCode => Object.hash(
    id,
    caseId,
    senderId,
    text,
    createdAt,
    Object.hashAll(mentions),
  );
}
