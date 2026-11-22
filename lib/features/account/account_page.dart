import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/gavel_theme.dart';
import 'account_session.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.session,
    this.account,
    this.loading = false,
    this.onRetry,
  });

  final AccountSession session;
  final Account? account;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

enum _AuthMode { signIn, register, reset }

class _AccountPageState extends State<AccountPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) _message = success;
    } on InviteUnavailable {
      if (mounted) _message = 'This invite is unavailable. Check the code or ask your team for a new one.';
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _message = switch (error.code) {
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' => 'Check your email and password.',
          'popup-closed-by-user' || 'cancelled-popup-request' => null,
          'popup-blocked' =>
            'Allow pop-ups for this site, then try Google sign-in again.',
          'unauthorized-domain' => 'Google sign-in is unavailable on this site. You can still sign in with email.',
          'operation-not-allowed' => 'Google sign-in is unavailable right now. You can still sign in with email.',
          'account-exists-with-different-credential' => 'This email already has an account. Sign in the way you originally signed up.',
          'weak-password' => 'Choose a stronger password.',
          'email-already-in-use' => 'This email already has an account. Sign in or reset your password.',
          'too-many-requests' => 'Too many attempts. Try again later.',
          'network-request-failed' => 'Check your connection and try again.',
          _ => 'Account request failed. Try again.',
        };
      }
    } catch (_) {
      if (mounted) {
        _message = 'Request failed. Check your connection and try again.';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeMode(_AuthMode mode) => setState(() {
    _mode = mode;
    _password.clear();
    _message = null;
  });

  void _submitAuth() {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final password = _password.text;
    switch (_mode) {
      case _AuthMode.signIn:
        _run(() => widget.session.signIn(email, password));
      case _AuthMode.register:
        _run(() => widget.session.register(email, password));
      case _AuthMode.reset:
        _run(() async {
          try {
            await widget.session.resetPassword(email);
          } on FirebaseAuthException catch (error) {
            if (error.code != 'user-not-found') rethrow;
          }
        }, success: 'If an account exists, check your email for a reset link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final retry = widget.onRetry;
    final title = widget.loading
        ? 'Gavel'
        : retry != null
        ? 'Account unavailable'
        : account == null
        ? switch (_mode) {
            _AuthMode.signIn => 'Sign in to Gavel',
            _AuthMode.register => 'Create your account',
            _AuthMode.reset => 'Reset your password',
          }
        : account.verified
        ? 'Join your team'
        : 'Verify your email';
    return MaterialApp(
      title: 'Gavel',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: GavelThemeVariant.light.data,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 18,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Builder(
                        builder: (context) => Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (widget.loading || _busy)
                        const LinearProgressIndicator(),
                      if (retry != null) ...[
                        const Text('Check your connection and try again.'),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _busy ? null : retry,
                          child: const Text('Retry'),
                        ),
                      ] else if (!widget.loading && account == null) ...[
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) =>
                              (value ?? '').trim().contains('@')
                              ? null
                              : 'Enter your email.',
                        ),
                        if (_mode != _AuthMode.reset)
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            autofillHints: [
                              _mode == _AuthMode.register
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            validator: (value) => (value ?? '').isEmpty
                                ? 'Enter your password.'
                                : null,
                            onFieldSubmitted: (_) {
                              if (!_busy) _submitAuth();
                            },
                          ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _busy ? null : _submitAuth,
                          child: Text(switch (_mode) {
                            _AuthMode.signIn => 'Sign in',
                            _AuthMode.register => 'Create account',
                            _AuthMode.reset => 'Send reset link',
                          }),
                        ),
                        if (_mode != _AuthMode.reset &&
                            widget.session.supportsGoogleSignIn)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xff1f1f1f),
                              side: const BorderSide(color: Color(0xff747775)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => _run(widget.session.signInWithGoogle),
                            icon: Image.asset(
                              'assets/auth/google-g.png',
                              width: 20,
                              height: 20,
                              excludeFromSemantics: true,
                            ),
                            label: const Text('Sign in with Google'),
                          ),
                        if (_mode == _AuthMode.signIn) ...[
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _changeMode(_AuthMode.register),
                            child: const Text('Create an account'),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _changeMode(_AuthMode.reset),
                            child: const Text('Forgot password?'),
                          ),
                        ] else
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _changeMode(_AuthMode.signIn),
                            child: const Text('Back to sign in'),
                          ),
                      ] else if (!widget.loading && account != null) ...[
                        Text(account.email),
                        if (account.verified) ...[
                          const Text(
                            'Enter the invite code shared by your team.',
                          ),
                          TextFormField(
                            controller: _invite,
                            enabled: !_busy,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Invite code',
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Enter your invite code.'
                                : null,
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: _busy
                                ? null
                                : () {
                                    if (_form.currentState!.validate()) {
                                      _run(
                                        () => widget.session.joinTeam(
                                          account.uid,
                                          _invite.text.trim(),
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Join team'),
                          ),
                        ] else ...[
                          const Text(
                            'Send a verification link, open it from your email, then return here.',
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                    widget.session.sendVerification,
                                    success: 'Verification link sent. Check your email.',
                                  ),
                            child: const Text('Send verification link'),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _run(
                                    widget.session.refreshVerification,
                                    success: 'Email is still unverified. Open the link and try again.',
                                  ),
                            child: const Text('I verified my email'),
                          ),
                        ],
                      ],
                      if (account != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _run(widget.session.signOut),
                          child: const Text('Sign out'),
                        ),
                      if (_message case final message?)
                        Semantics(liveRegion: true, child: Text(message)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
