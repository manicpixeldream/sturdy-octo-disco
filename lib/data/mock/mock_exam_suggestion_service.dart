import '../models/witness.dart';
import '../models/timing_rule.dart';
import '../services/exam_suggestion_service.dart';

class MockExamSuggestionService implements ExamSuggestionService {
  @override
  Future<List<String>> suggest(Witness witness, TrialPhase phase) async =>
      phase == TrialPhase.direct
      ? [
          'Please introduce yourself and explain your role in the events described in your affidavit.',
          'What did you personally observe, and how do you remember the sequence of events?',
          'Which details in your affidavit help explain your observations?',
        ]
      : [
          'Which parts of your account are based on personal observation rather than information from others?',
          'What limits were there on your ability to observe or recall the events?',
          'Where does your affidavit describe the detail you have just mentioned?',
        ];
}
