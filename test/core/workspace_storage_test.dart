import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/storage/workspace_storage.dart';

void main() {
  for (final invalid in ['{', '[]']) {
    test('a new record replaces an unreadable collection ($invalid)', () async {
      final data = {'gavel.workspace.v1.tasks': invalid};
      final storage = WorkspaceStorage(
        (key) => data[key],
        (key, value) => data[key] = value,
      );
      addTearDown(storage.saveFailed.dispose);

      storage.putRecord('tasks', 'new', {'title': 'Rehearse'});
      storage.putRecord('tasks', 'next', {'title': 'Review'});
      expect(storage.records('tasks', (record) => record['title']! as String), [
        'Rehearse',
        'Review',
      ]);
      await Future<void>.value();
      expect(storage.saveFailed.value, isTrue);
    });
  }
}
