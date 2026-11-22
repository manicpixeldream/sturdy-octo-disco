import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef Account = ({String uid, String email, bool verified});

abstract interface class AccountSession {
  Stream<Account?> accounts();
  Stream<String?> membership(String uid);
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> sendVerification();
  Future<void> refreshVerification();
  Future<void> resetPassword(String email);
  Future<void> joinTeam(String uid, String code);
  Future<void> signOut();
}

class InviteUnavailable implements Exception {
  const InviteUnavailable();
}

class FirebaseAccountSession implements AccountSession {
  FirebaseAccountSession(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<Account?> accounts() => _auth.idTokenChanges().map(
    (user) => user == null
        ? null
        : (
            uid: user.uid,
            email: user.email ?? '',
            verified: user.emailVerified,
          ),
  );

  DocumentReference<Map<String, dynamic>> _membership(String uid) =>
      _firestore.collection('memberships').doc(uid);

  @override
  Stream<String?> membership(String uid) {
    var confirmed = false;
    return _membership(uid)
        .snapshots(includeMetadataChanges: true)
        .where(
          (snapshot) =>
              !snapshot.metadata.isFromCache &&
              !snapshot.metadata.hasPendingWrites,
        )
        .map((snapshot) {
          confirmed = true;
          return snapshot.data()?['teamId'] as String?;
        })
        .distinct()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            if (!confirmed) {
              sink.addError(StateError('Could not check team membership.'));
              sink.close();
            }
          },
        );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendVerification() => _auth.currentUser!.sendEmailVerification();

  @override
  Future<void> refreshVerification() async {
    final user = _auth.currentUser!;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> joinTeam(String uid, String code) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{24,64}$').hasMatch(code)) {
      throw const InviteUnavailable();
    }
    try {
      final invite = await _firestore
          .collection('teamInvites')
          .doc(code)
          .get(const GetOptions(source: Source.server));
      final teamId = invite.data()?['teamId'] as String?;
      if (teamId == null) throw const InviteUnavailable();
      await _membership(uid).set({'teamId': teamId, 'inviteCode': code});
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') throw const InviteUnavailable();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
