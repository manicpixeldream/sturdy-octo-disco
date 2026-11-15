import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../data/models/chat_message.dart';
import '../data/models/timing_rule.dart';
import '../core/router/routes.dart';
import '../core/storage/workspace_storage.dart';
import '../data/repositories/chat_repository.dart';
import 'case_controller.dart';
import 'team_controller.dart';
import 'task_controller.dart';
import '../core/clock.dart';
import 'load_controller.dart';

class ChatController extends LoadController {
  ChatController(
    this._repository,
    this.cases,
    this.team,
    this.tasks,
    this.clock,
    this.currentTeammateId, {
    this.requestTimeout = const Duration(seconds: 20),
    this.storage,
  }) {
    cases.addListener(_caseChanged);
    _caseChanged();
  }
  final ChatRepository _repository;
  final CaseController cases;
  final TeamController team;
  final TaskController tasks;
  final Clock clock;
  final String currentTeammateId;
  final Duration requestTimeout;
  final WorkspaceStorage? storage;
  String draftText = '';
  List<ChatMention> draftMentions = const [];

  void saveDraft(String text, List<ChatMention> mentions) {
    draftText = text;
    draftMentions = List.unmodifiable(mentions);
    if (_caseId case final id?) {
      storage?.write('chatDraft.$id', {
        'text': text,
        'mentions': mentions.map((mention) => mention.toMap()).toList(),
        'pending': _failedDraft?.toMap(),
      });
    }
  }

  String? _caseId;
  String? get caseId => _caseId;
  List<ChatMessage> _messages = const [];
  List<ChatMessage> get messages => _messages;
  bool _loaded = false, _sending = false, _sendFailed = false;
  bool get isLoaded => _loaded;
  bool get isSending => _sending;
  bool get sendFailed => _sendFailed;
  ChatMessage? _failedDraft;
  int _version = 0, _sequence = 0;
  final _messageNamespace = Random.secure()
      .nextInt(0x1000000)
      .toRadixString(16);
  void _caseChanged() {
    final id = cases.activeCase?.id;
    if (!isDisposed && id != null && id != _caseId) unawaited(load());
  }

  Future<void> load() async {
    final id = cases.activeCase?.id;
    if (isDisposed || id == null || (_sending && id == _caseId)) return;
    if (id != _caseId) {
      _version++;
      _caseId = id;
      _messages = const [];
      _loaded = false;
      _sending = false;
      _sendFailed = false;
      _failedDraft = null;
      draftText = '';
      draftMentions = const [];
      storage?.read('chatDraft.$id', (value) {
        final record = value as Map<String, dynamic>;
        final text = record['text'] as String;
        final mentions = (record['mentions'] as List)
            .map(
              (item) =>
                  ChatMention.fromMap(Map<String, Object?>.from(item as Map)),
            )
            .toList();
        final pending = record['pending'] as Map?;
        _failedDraft = pending == null
            ? null
            : ChatMessage.fromMap(Map<String, Object?>.from(pending));
        draftText = text;
        draftMentions = List.unmodifiable(mentions);
        return true;
      });
    }
    await loadWith(() => _repository.fetchMessages(id), (messages) {
      final ids = <String>{};
      if (messages.any((m) => m.caseId != id || !ids.add(m.id))) {
        throw StateError('Invalid channel data');
      }
      _messages = List.unmodifiable(messages);
      if (_failedDraft case final pending?) {
        final matchesDraft =
            draftText.trim() == pending.text &&
            listEquals(
              draftMentions.map((mention) => mention.id).toList(),
              pending.mentions.map((mention) => mention.id).toList(),
            );
        if (ids.contains(pending.id)) {
          _failedDraft = null;
          _sendFailed = false;
          saveDraft(
            matchesDraft ? '' : draftText,
            matchesDraft ? const [] : draftMentions,
          );
        } else {
          _sendFailed = matchesDraft;
        }
      }
      _loaded = true;
    });
  }

  List<ChatMention> get availableMentions => List.unmodifiable([
    for (final task in tasks.tasks)
      ChatMention(
        kind: ChatMentionKind.task,
        itemId: task.id,
        label: task.title,
      ),
    for (final phase in const [TrialPhase.opening, TrialPhase.closing])
      ChatMention(
        kind: ChatMentionKind.draft,
        itemId: Routes.argument(phase.name),
        label: phase.label,
      ),
    for (final witness in cases.witnesses)
      for (final phase in const [TrialPhase.direct, TrialPhase.cross])
        ChatMention(
          kind: ChatMentionKind.draft,
          itemId: Routes.exam(witness.id, phase: phase.name),
          label: '${witness.name} · ${phase.label}',
        ),
    for (final exhibit in cases.exhibits)
      ChatMention(
        kind: ChatMentionKind.exhibit,
        itemId: exhibit.id,
        label: '${exhibit.label} · ${exhibit.title}',
      ),
  ]);
  bool mentionAvailable(ChatMention mention) =>
      availableMentions.any((m) => m.id == mention.id);
  Future<bool> send(String text, List<ChatMention> mentions) async {
    final body = text.trim();
    if (isDisposed ||
        !_loaded ||
        isLoading ||
        _sending ||
        !team.isLoaded ||
        !tasks.isLoaded ||
        cases.loadFailed ||
        team.loadFailed ||
        tasks.loadFailed ||
        team.byId(currentTeammateId) == null ||
        body.characters.length > 2000 ||
        (body.isEmpty && mentions.isEmpty) ||
        mentions.length > 5 ||
        mentions.map((m) => m.id).toSet().length != mentions.length) {
      return false;
    }
    final canonical = <ChatMention>[];
    for (final mention in mentions) {
      final found = availableMentions
          .where((m) => m.id == mention.id)
          .firstOrNull;
      if (found == null) {
        _sendFailed = true;
        notifyListeners();
        return false;
      }
      canonical.add(found);
    }
    final previous = _failedDraft;
    ChatMessage draft;
    if (previous != null &&
        previous.caseId == _caseId &&
        previous.text == body &&
        listEquals(previous.mentions, canonical)) {
      draft = previous;
    } else {
      String id;
      do {
        id =
            'chat_${(++_sequence).toString().padLeft(8, '0')}_$_messageNamespace';
      } while (_messages.any((m) => m.id == id));
      draft = ChatMessage(
        id: id,
        caseId: _caseId!,
        senderId: currentTeammateId,
        text: body,
        createdAt: clock.now(),
        mentions: canonical,
      );
    }
    final version = _version;
    _failedDraft = draft;
    saveDraft(text, mentions);
    _sending = true;
    _sendFailed = false;
    notifyListeners();
    try {
      final saved = await _repository
          .sendMessage(draft)
          .timeout(requestTimeout);
      if (isDisposed || version != _version) return false;
      if (saved.id != draft.id ||
          saved.caseId != draft.caseId ||
          saved.senderId != draft.senderId ||
          saved.text != draft.text ||
          !listEquals(saved.mentions, draft.mentions)) {
        throw StateError('Invalid sent message');
      }
      _messages = List.unmodifiable([
        ..._messages.where((m) => m.id != saved.id),
        saved,
      ]);
      _failedDraft = null;
      saveDraft('', const []);
      return true;
    } catch (_) {
      if (!isDisposed && version == _version) {
        _sendFailed = true;
        _failedDraft = draft;
      }
      return false;
    } finally {
      if (!isDisposed && version == _version) {
        _sending = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    cases.removeListener(_caseChanged);
    _version++;
    super.dispose();
  }
}
