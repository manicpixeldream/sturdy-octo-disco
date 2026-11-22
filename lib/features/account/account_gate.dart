import 'package:material_ui/material_ui.dart';

import 'account_page.dart';
import 'account_session.dart';

class AccountGate extends StatefulWidget {
  const AccountGate({
    super.key,
    required this.session,
    required this.workspace,
  });

  final AccountSession session;
  final Widget Function(Account account, String teamId) workspace;

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  late Stream<Account?> _accounts = widget.session.accounts();

  @override
  Widget build(BuildContext context) => StreamBuilder<Account?>(
    stream: _accounts,
    builder: (context, snapshot) {
      final account = snapshot.data;
      if (snapshot.hasError) {
        return AccountPage(
          session: widget.session,
          onRetry: () => setState(() => _accounts = widget.session.accounts()),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return AccountPage(session: widget.session, loading: true);
      }
      if (account == null || !account.verified) {
        return AccountPage(
          key: ValueKey(account?.uid),
          session: widget.session,
          account: account,
        );
      }
      return _MembershipGate(
        key: ValueKey(account.uid),
        session: widget.session,
        account: account,
        workspace: widget.workspace,
      );
    },
  );
}

class _MembershipGate extends StatefulWidget {
  const _MembershipGate({
    super.key,
    required this.session,
    required this.account,
    required this.workspace,
  });

  final AccountSession session;
  final Account account;
  final Widget Function(Account account, String teamId) workspace;

  @override
  State<_MembershipGate> createState() => _MembershipGateState();
}

class _MembershipGateState extends State<_MembershipGate> {
  late Stream<String?> _membership = widget.session.membership(
    widget.account.uid,
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: _membership,
    builder: (context, snapshot) {
      final teamId = snapshot.data;
      if (teamId != null && !snapshot.hasError) {
        return KeyedSubtree(
          key: ValueKey(teamId),
          child: widget.workspace(widget.account, teamId),
        );
      }
      return AccountPage(
        session: widget.session,
        account: widget.account,
        loading: snapshot.connectionState == ConnectionState.waiting,
        onRetry: snapshot.hasError
            ? () => setState(
                () =>
                    _membership = widget.session.membership(widget.account.uid),
              )
            : null,
      );
    },
  );
}
