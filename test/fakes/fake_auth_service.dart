// 6.3 A sign-in backend in memory for tests (spec 016): no network.
import 'dart:async';

import 'package:focus_app/services/auth_service.dart';

class FakeAuthService implements AuthService {
  final Map<String, ({String uid, String password})> _users = {};
  final StreamController<AccountUser?> _changes = StreamController<AccountUser?>.broadcast();
  AccountUser? _current;
  int _nextUid = 1;

  /// When set, every call throws this code (e.g. 'network-request-failed').
  String? failWith;

  /// When set, [reload] throws this code (account deleted elsewhere, sign-in expired).
  String? reloadFailure;

  /// Emails that asked for a reset link and exist.
  final List<String> resetsSent = [];

  /// Creates an account without signing in.
  AccountUser addUser(String email, String password) {
    final uid = 'uid${_nextUid++}';
    _users[email] = (uid: uid, password: password);
    return AccountUser(uid: uid, email: email);
  }

  void _check() {
    if (failWith != null) throw AuthFailure(failWith!);
  }

  void _set(AccountUser? user) {
    _current = user;
    _changes.add(user);
  }

  @override
  Stream<AccountUser?> authStateChanges() => _changes.stream;

  @override
  AccountUser? get currentUser => _current;

  @override
  Future<AccountUser> signUp(String email, String password) async {
    _check();
    if (_users.containsKey(email)) throw const AuthFailure('email-already-in-use');
    if (password.length < 6) throw const AuthFailure('weak-password');
    final user = addUser(email, password);
    _set(user);
    return user;
  }

  @override
  Future<AccountUser> signIn(String email, String password) async {
    _check();
    final entry = _users[email];
    if (entry == null || entry.password != password) {
      throw const AuthFailure('invalid-credential');
    }
    final user = AccountUser(uid: entry.uid, email: email);
    _set(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _check();
    if (_users.containsKey(email)) resetsSent.add(email);
  }

  @override
  Future<void> reload() async {
    _check();
    if (reloadFailure != null) throw AuthFailure(reloadFailure!);
  }

  @override
  Future<void> reauthenticate(String password) async {
    _check();
    final email = _current?.email;
    if (email == null || _users[email]?.password != password) {
      throw const AuthFailure('invalid-credential');
    }
  }

  @override
  Future<void> deleteUser() async {
    _check();
    final email = _current?.email;
    if (email != null) _users.remove(email);
    _set(null);
  }

  /// Simulates the account being deleted on another phone.
  void deleteElsewhere(String email) => _users.remove(email);

  bool hasUser(String email) => _users.containsKey(email);

  @override
  Future<void> signOut() async => _set(null);
}
