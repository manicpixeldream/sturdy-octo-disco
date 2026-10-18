import '../models/research_message.dart';
import '../models/research_source.dart';

abstract interface class ResearchService {
  Future<List<ResearchSource>> fetchSources(String caseId);
  Future<ResearchReply> ask({
    required String caseId,
    required String question,
    required List<ResearchMessage> history,
  });
}
