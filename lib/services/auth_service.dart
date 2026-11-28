// 6.3 Tài khoản (spec 016, contracts/services.md): what the app needs from the sign-in backend.
// Only firebase_auth_service.dart talks to Firebase; tests use a fake.

/// The signed-in account: the backend's id and the email. Nothing else is read (FR-019).
class AccountUser {
  const AccountUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

/// A sign-in error; [code] is mapped to Vietnamese text by `authErrorMessage`.
class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final String code;

  @override
  String toString() => 'AuthFailure($code)';
}

abstract class AuthService {
  /// Emits the current user (null when signed out) whenever it changes.
  Stream<AccountUser?> authStateChanges();

  AccountUser? get currentUser;

  Future<AccountUser> signUp(String email, String password);

  Future<AccountUser> signIn(String email, String password);

  Future<void> sendPasswordReset(String email);

  /// Asks the backend whether the account still exists; throws [AuthFailure] if not.
  Future<void> reload();

  /// Needed right before deleting the account.
  Future<void> reauthenticate(String password);

  /// Deletes the sign-in account only; its records are deleted by the remote store first.
  Future<void> deleteUser();

  Future<void> signOut();
}
