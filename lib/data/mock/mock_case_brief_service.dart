import '../models/case_brief.dart';
import '../services/case_brief_service.dart';

class MockCaseBriefService implements CaseBriefService {
  const MockCaseBriefService(this.brief);

  final CaseBrief brief;

  @override
  Future<CaseBrief> fetchBrief(String caseId) async {
    if (caseId != brief.caseId) throw StateError('No brief for this case.');
    return brief;
  }
}
