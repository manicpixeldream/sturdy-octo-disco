abstract final class Routes {
  static const String home = '/home';
  static const String caseFile = '/case';
  static const String research = '/research';
  static const String team = '/team';
  static const String teamChat = '/team/chat';
  static String teamTask(String id) =>
      Uri(pathSegments: ['', 'team', 'task', id]).toString();
  static String assignRole(String id) =>
      '/team/assign/${Uri.encodeComponent(id)}';

  static const String me = '/me';
  static const String schedule = '/me/schedule';

  static String exam(
    String witnessId, {
    String phase = 'direct',
    String? questionId,
  }) => Uri(
    pathSegments: ['', 'case', 'witness', witnessId, 'exam'],
    queryParameters: {'phase': phase, 'question': ?questionId},
  ).toString();
  static String examCitation(String reference) {
    final parts = reference.split('|');
    if (parts.length != 3 || !['direct', 'cross'].contains(parts[1])) {
      return caseFile;
    }
    return exam(parts[0], phase: parts[1], questionId: parts[2]);
  }

  static String affidavit(String id) =>
      '/case/affidavit/${Uri.encodeComponent(id)}';

  static String researchSource(String id) =>
      '/research/source/${Uri.encodeComponent(id)}';
  static String researchAnswer(String id) =>
      Uri(path: research, queryParameters: {'message': id}).toString();
  static String caseBrief(String id) => Uri(
    path: caseFile,
    queryParameters: {'section': 'brief', 'fact': id},
  ).toString();

  static const String gallery = '/gallery';
}
