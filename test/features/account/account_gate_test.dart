import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/features/account/account_gate.dart';
import 'package:gavel/features/account/account_session.dart';
import 'package:material_ui/material_ui.dart';

class _Session implements AccountSession {
  final auth = StreamController<Account?>();
  final teams = <String, StreamController<String?>>{};
  final joins = <(String, String)>[];

  @override
  Stream<Account?> accounts() => auth.stream;

  @override
  Stream<String?> membership(String uid) async* {
    yield null;
    yield* teams.putIfAbsent(uid, StreamController<String?>.broadcast).stream;
  }

  @override
  Future<void> joinTeam(String uid, String code) async {
    joins.add((uid, code));
    if (code == 'invalid') throw const InviteUnavailable();
    teams[uid]!.add('trial-team');
  }

  @override
  Future<void> signOut() async => auth.add(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('workspace requires a verified account and live membership', (
    tester,
  ) async {
    final session = _Session();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await session.auth.close();
      for (final team in session.teams.values) {
        await team.close();
      }
    });
    await tester.pumpWidget(
      AccountGate(
        session: session,
        workspace: (account, teamId) =>
            MaterialApp(home: Scaffold(body: Text('${account.uid}/$teamId'))),
      ),
    );

    session.auth.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Sign in to Gavel'), findsOneWidget);
    const account = (
      uid: 'first',
      email: 'student@example.com',
      verified: false,
    );
    session.auth.add(account);
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(session.teams, isEmpty);

    session.auth.add((uid: account.uid, email: account.email, verified: true));
    await tester.pumpAndSettle();
    expect(find.text('Join your team'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.tap(find.text('Join team'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This invite is unavailable'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'sample-invite');
    await tester.tap(find.text('Join team'));
    await tester.pumpAndSettle();
    expect(session.joins, [('first', 'invalid'), ('first', 'sample-invite')]);
    expect(find.text('first/trial-team'), findsOneWidget);

    session.auth.add((
      uid: 'second',
      email: 'other@example.com',
      verified: true,
    ));
    await tester.pumpAndSettle();
    expect(find.text('first/trial-team'), findsNothing);
    expect(find.text('Join your team'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to Gavel'), findsOneWidget);
  });
}
