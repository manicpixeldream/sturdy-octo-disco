import '../models/witness.dart';
import '../models/timing_rule.dart';

abstract interface class ExamSuggestionService {
  Future<List<String>> suggest(Witness witness, TrialPhase phase);
}
