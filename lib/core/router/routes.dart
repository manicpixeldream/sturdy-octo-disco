abstract final class Routes {
  static const String home = '/home';
  static const String caseFile = '/case';
  static const String research = '/research';
  static const String team = '/team';
  static const String me = '/me';

  static String affidavit(String id) =>
      '/case/affidavit/${Uri.encodeComponent(id)}';

  static const String gallery = '/gallery';
}
