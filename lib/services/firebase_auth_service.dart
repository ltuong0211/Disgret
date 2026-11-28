// 6.3 Tài khoản (spec 016, ADR-0013): email + password sign-in on Firebase Authentication. The only
// file that imports firebase_auth. Every call times out after 15 s so a missing network never
// hangs a screen.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() {
    // Reset and verification emails in Vietnamese (research.md R9).
    unawaited(_auth.setLanguageCode('vi'));
  }

  static const Duration _timeout = Duration(seconds: 15);

  FirebaseAuth get _auth => FirebaseAuth.instance;

  static AccountUser? _toUser(User? user) =>
      user == null ? null : AccountUser(uid: user.uid, email: user.email ?? '');

  /// Runs a Firebase call and turns its errors into [AuthFailure] codes.
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(error.code);
    } on TimeoutException {
      throw const AuthFailure('network-request-failed');
    }
  }

  @override
  Stream<AccountUser?> authStateChanges() => _auth.authStateChanges().map(_toUser);

  @override
  AccountUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Future<AccountUser> signUp(String email, String password) async {
    final result = await _call(
      () => _auth.createUserWithEmailAndPassword(email: email, password: password),
    );
    // A verification email helps with password resets but is not required (spec Assumptions).
    unawaited(result.user?.sendEmailVerification().catchError((_) {}));
    return _toUser(result.user)!;
  }

  @override
  Future<AccountUser> signIn(String email, String password) async {
    final result = await _call(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
    return _toUser(result.user)!;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _call(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> reload() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('user-token-expired');
    await _call(user.reload);
  }

  @override
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const AuthFailure('user-token-expired');
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await _call(() => user.reauthenticateWithCredential(credential));
  }

  @override
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _call(user.delete);
  }

  @override
  Future<void> signOut() => _call(_auth.signOut);
}
