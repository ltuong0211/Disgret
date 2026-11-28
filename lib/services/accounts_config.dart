// 6.3 Tài khoản (spec 016, research.md R2): Firebase settings come from
// `flutter run --dart-define-from-file=firebase.env.json` (git-ignored, supplied by the project
// lead). Without them every account entry point is hidden (FR-003) and nothing goes online.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AccountsConfig {
  AccountsConfig._();

  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  /// True when this build carries the four values and runs on Android (web is for UI work only).
  static bool get isConfigured =>
      !kIsWeb && [_apiKey, _appId, _projectId, _senderId].every((value) => value.isNotEmpty);

  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
  );

  /// Set by main.dart once Firebase started; accounts are offered only then.
  static bool ready = false;
}
