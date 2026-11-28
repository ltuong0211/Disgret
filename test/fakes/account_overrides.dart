// 6.3 Turns accounts on in widget tests with in-memory fakes (spec 016): no Firebase, no network.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:focus_app/providers/account_providers.dart';

import 'fake_auth_service.dart';
import 'in_memory_remote_store.dart';

List<Override> accountOverrides(FakeAuthService auth, InMemoryRemoteStore remote) => [
  accountsAvailableProvider.overrideWithValue(true),
  authServiceProvider.overrideWithValue(auth),
  remoteStoreProvider.overrideWithValue(remote),
];
