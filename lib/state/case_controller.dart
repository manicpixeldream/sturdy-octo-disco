import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/dates.dart';
import '../data/models/case_file.dart';
import '../data/models/affidavit.dart';
import '../data/models/case_brief.dart';
import '../data/models/stipulation.dart';
import '../data/models/timing_rule.dart';
import '../data/models/exhibit.dart';
import '../data/models/witness.dart';
import '../data/repositories/case_repository.dart';
import '../data/services/case_brief_service.dart';

class CaseController extends ChangeNotifier {
  CaseController(this._repository, this._clock, {this.briefService});

  final CaseRepository _repository;
  final Clock _clock;
  final CaseBriefService? briefService;
  bool _disposed = false;
  int _loadGeneration = 0;
  int _briefRequest = 0;

  CaseFile? _activeCase;
  List<Exhibit> _exhibits = const [];
  List<Witness> _witnesses = const [];
  List<Affidavit> _affidavits = const [];
  List<Stipulation> _stipulations = const [];
  List<TimingRule> _timingRules = const [];
  CaseBrief? _brief;
  bool _isBriefLoading = false;
  bool _briefFailed = false;

  bool get isLoaded => _activeCase != null;
  CaseFile? get activeCase => _activeCase;
  List<Exhibit> get exhibits => _exhibits;
  List<Witness> get witnesses => _witnesses;
  List<Affidavit> get affidavits => _affidavits;
  List<Stipulation> get stipulations => _stipulations;
  List<TimingRule> get timingRules => _timingRules;
  CaseBrief? get brief => _brief;
  bool get isBriefLoading => _isBriefLoading;
  bool get briefFailed => _briefFailed;

  Exhibit? exhibitById(String id) =>
      _exhibits.where((e) => e.id == id).firstOrNull;

  Affidavit? affidavitById(String id) =>
      _affidavits.where((a) => a.id == id).firstOrNull;

  Witness? witnessById(String id) =>
      _witnesses.where((w) => w.id == id).firstOrNull;

  /// Negative once the trial date has passed.
  int get daysUntilTrial {
    final activeCase = _activeCase;
    if (activeCase == null) return 0;
    return daysBetween(_clock.now(), activeCase.trialDate);
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    final activeCase = await _repository.fetchActiveCase();
    final (exhibits, witnesses, affidavits, stipulations, timingRules) = await (
      _repository.fetchExhibits(activeCase.id),
      _repository.fetchWitnesses(activeCase.id),
      _repository.fetchAffidavits(activeCase.id),
      _repository.fetchStipulations(activeCase.id),
      _repository.fetchTimingRules(activeCase.id),
    ).wait;
    if (_disposed || generation != _loadGeneration) return;
    _activeCase = activeCase;
    _exhibits = List.unmodifiable(exhibits);
    _witnesses = List.unmodifiable(witnesses);
    _affidavits = List.unmodifiable(affidavits);
    _stipulations = List.unmodifiable(stipulations);
    _timingRules = List.unmodifiable(timingRules);
    _brief = null;
    notifyListeners();
    await loadBrief();
  }

  Future<void> loadBrief() async {
    final caseId = _activeCase?.id;
    final service = briefService;
    if (_disposed || caseId == null || service == null) {
      return;
    }
    final generation = _loadGeneration;
    final request = ++_briefRequest;
    _isBriefLoading = true;
    _briefFailed = false;
    notifyListeners();
    try {
      final brief = await service.fetchBrief(caseId);
      if (brief.caseId != caseId) {
        throw StateError('Brief belongs to another case.');
      }
      if (!_disposed &&
          generation == _loadGeneration &&
          request == _briefRequest) {
        _brief = brief;
      }
    } catch (_) {
      if (!_disposed &&
          generation == _loadGeneration &&
          request == _briefRequest) {
        _briefFailed = true;
      }
    } finally {
      if (!_disposed &&
          generation == _loadGeneration &&
          request == _briefRequest) {
        _isBriefLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
