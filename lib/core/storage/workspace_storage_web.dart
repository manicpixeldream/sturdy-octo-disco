import 'package:web/web.dart' as web;

import 'workspace_storage.dart';

WorkspaceStorage openWorkspaceStorage() => WorkspaceStorage(
  (key) => web.window.localStorage.getItem(key),
  (key, value) => web.window.localStorage.setItem(key, value),
);
