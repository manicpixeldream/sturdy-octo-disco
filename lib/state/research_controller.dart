import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/citation.dart';
import '../data/models/research_message.dart';
import '../data/models/research_source.dart';
import '../data/services/research_service.dart';
import 'case_controller.dart';
import 'load_controller.dart';

class ResearchController extends LoadController {
  ResearchController(
    this._service,
    this._cases, {
    this.requestTimeout = const Duration(seconds: 20),
  }) {
    _cases.addListener(_caseChanged);
    _caseChanged();
  }

  final ResearchService _service;
  final CaseController _cases;
  final Duration requestTimeout;
  String? _caseId;
  bool _loaded = false;
  List<ResearchSource> _sources = const [];
  final List<ResearchMessage> _messages = [];
  final Map<String, Citation> _citations = {};
  final Set<String> _saved = {};
  bool _sending = false;
  String? _failedMessageId;
  int _sequence = 0;
  int _requestVersion = 0;

  bool get isLoaded => _loaded;
  bool get isSending => _sending;
  bool get replyFailed => _failedMessageId != null;
  String? get caseId => _caseId;
  List<ResearchSource> get sources => _sources;
  List<ResearchMessage> get messages => List.unmodifiable(_messages);
  List<ResearchSource> get savedSources =>
      List.unmodifiable(_sources.where((s) => _saved.contains(s.id)));
  ResearchSource? sourceById(String id) =>
      _sources.where((s) => s.id == id).firstOrNull;
  bool isSaved(String id) => _saved.contains(id);
  List<Citation> citationsFor(String sourceId) =>
      List.unmodifiable(_citations.values.where((c) => c.sourceId == sourceId));

  void _caseChanged() {
    if (isDisposed) return;
    final id = _cases.activeCase?.id;
    if (id != null && id != _caseId) {
      unawaited(load());
    } else {
      _syncBriefCitations();
    }
  }

  Future<void> load() async {
    final id = _cases.activeCase?.id;
    if (id == null || isDisposed) return;
    if (id != _caseId) {
      _requestVersion++;
      _messages.clear();
      _citations.clear();
      _saved.clear();
      _sources = const [];
      _sending = false;
      _failedMessageId = null;
      _loaded = false;
    }
    _caseId = id;
    await loadWith(() => _service.fetchSources(id), (sources) {
      final ids = <String>{};
      for (final source in sources) {
        if (!ids.add(source.id) ||
            (source.caseId != null && source.caseId != id)) {
          throw StateError('Invalid source catalogue.');
        }
      }
      _sources = List.unmodifiable(sources);
      _loaded = true;
      _saved.removeWhere((id) => !ids.contains(id));
      _citations.removeWhere((_, citation) => !ids.contains(citation.sourceId));
      _syncBriefCitations();
    });
  }

  void toggleSaved(String sourceId) {
    if (sourceById(sourceId) == null) {
      throw ArgumentError.value(sourceId, 'sourceId');
    }
    if (!_saved.add(sourceId)) _saved.remove(sourceId);
    notifyListeners();
  }

  /// Other features can register real usages without inventing a "Cited in" entry.
  void addCitation(Citation citation) {
    if (sourceById(citation.sourceId) == null) {
      throw ArgumentError.value(citation.sourceId, 'sourceId');
    }
    if (_citations[citation.id] == citation) return;
    _citations[citation.id] = citation;
    notifyListeners();
  }

  void _syncBriefCitations() {
    if (!_loaded || isDisposed) return;
    final next = <String, Citation>{};
    final brief = _cases.brief;
    if (brief?.caseId == _caseId) {
      for (final fact in brief!.facts) {
        for (final link in fact.evidence) {
          final source = sourceById(link.sourceId);
          if (source?.caseId == _caseId && source?.evidenceKind == link.kind) {
            final citation = Citation(
              sourceId: link.sourceId,
              location: CitationLocation.caseBrief,
              referenceId: fact.id,
              label: fact.text,
            );
            next[citation.id] = citation;
          }
        }
      }
    }
    final old = Map.fromEntries(
      _citations.entries.where(
        (e) => e.value.location == CitationLocation.caseBrief,
      ),
    );
    if (mapEquals(old, next)) return;
    _citations.removeWhere(
      (_, value) => value.location == CitationLocation.caseBrief,
    );
    _citations.addAll(next);
    notifyListeners();
  }

  Future<bool> send(String question) async {
    final text = question.trim();
    if (isDisposed ||
        !isLoaded ||
        _sending ||
        replyFailed ||
        text.isEmpty ||
        text.length > 2000) {
      return false;
    }
    final user = ResearchMessage(
      id: 'message_${++_sequence}',
      role: ResearchRole.user,
      text: text,
    );
    _messages.add(user);
    await _answer(user);
    return true;
  }

  Future<void> retryReply() async {
    final failed = _failedMessageId;
    if (failed == null || _sending || isDisposed) return;
    final user = _messages.where((m) => m.id == failed).firstOrNull;
    if (user != null) await _answer(user);
  }

  void dismissFailedReply() {
    if (_sending || _failedMessageId == null) return;
    _failedMessageId = null;
    notifyListeners();
  }

  Future<void> _answer(ResearchMessage user) async {
    final id = _caseId;
    if (id == null) return;
    final request = ++_requestVersion;
    _sending = true;
    _failedMessageId = null;
    notifyListeners();
    try {
      final reply = await _service
          .ask(
            caseId: id,
            question: user.text,
            history: List.unmodifiable(_messages),
          )
          .timeout(requestTimeout);
      if (isDisposed || request != _requestVersion || _caseId != id) return;
      if (reply.points.isEmpty ||
          reply.points.any(
            (p) =>
                p.text.trim().isEmpty ||
                p.sourceIds.isEmpty ||
                p.sourceIds.toSet().length != p.sourceIds.length ||
                p.sourceIds.any((sourceId) => sourceById(sourceId) == null),
          )) {
        throw StateError('Answer has missing or invalid citations.');
      }
      final answer = ResearchMessage(
        id: 'message_${++_sequence}',
        role: ResearchRole.assistant,
        text: reply.title,
        points: reply.points,
      );
      _messages.add(answer);
      for (final sourceId in reply.points.expand((p) => p.sourceIds).toSet()) {
        final citation = Citation(
          sourceId: sourceId,
          location: CitationLocation.answer,
          referenceId: answer.id,
          label: user.text,
        );
        _citations[citation.id] = citation;
      }
    } catch (_) {
      if (!isDisposed && request == _requestVersion) _failedMessageId = user.id;
    } finally {
      if (!isDisposed && request == _requestVersion) {
        _sending = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _cases.removeListener(_caseChanged);
    _requestVersion++;
    super.dispose();
  }
}
