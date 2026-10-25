abstract final class Routes {
  static const String home = '/home';
  static const String caseFile = '/case';
  static const String research = '/research';
  static const String team = '/team';
  static String assignRole(String id) =>
      '/team/assign/${Uri.encodeComponent(id)}';

  static const String me = '/me';
  static const String schedule = '/me/schedule';

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
