import 'package:web/web.dart' as web;

import 'workspace_storage.dart';

WorkspaceStorage openWorkspaceStorage({String? namespace}) {
  final prefix = namespace == null ? '' : 'gavel.account.$namespace.';
  return WorkspaceStorage(
    (key) => web.window.localStorage.getItem('$prefix$key'),
    (key, value) => web.window.localStorage.setItem('$prefix$key', value),
  );
}
