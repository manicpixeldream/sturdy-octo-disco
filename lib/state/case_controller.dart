import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/dates.dart';
import '../data/models/case_file.dart';
import '../data/models/exhibit.dart';
import '../data/models/witness.dart';
import '../data/repositories/case_repository.dart';

class CaseController extends ChangeNotifier {
  CaseController(this._repository, this._clock);

  final CaseRepository _repository;
  final Clock _clock;

  CaseFile? _activeCase;
  List<Exhibit> _exhibits = const [];
  List<Witness> _witnesses = const [];

  bool get isLoaded => _activeCase != null;
  CaseFile? get activeCase => _activeCase;
  List<Exhibit> get exhibits => _exhibits;
  List<Witness> get witnesses => _witnesses;

  /// Negative once the trial date has passed.
  int get daysUntilTrial {
    final activeCase = _activeCase;
    if (activeCase == null) return 0;
    return daysBetween(_clock.now(), activeCase.trialDate);
  }

  Future<void> load() async {
    final activeCase = await _repository.fetchActiveCase();
    final (exhibits, witnesses) = await (
      _repository.fetchExhibits(activeCase.id),
      _repository.fetchWitnesses(activeCase.id),
    ).wait;
    _activeCase = activeCase;
    _exhibits = exhibits;
    _witnesses = witnesses;
    notifyListeners();
  }
}
