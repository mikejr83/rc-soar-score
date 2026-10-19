import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/platform/app_bootstrap.dart';
import 'package:soar_score_contest/services/ui_account/ui_account.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import 'fake_auth_session.dart';

/// `AppBootstrap` stand-in for widget tests that need a signed-in app with a
/// local UI store: no embedded server, no database.
class FakeBootstrap extends AppBootstrap {
  FakeBootstrap(this.localUiStore, {this.uiAccount = const FixedUiAccount()})
    : _client = ApiClient(baseUrl: Uri.parse('http://localhost:1')),
      _auth = FakeAuthSession(signedIn: true, name: 'Pat Pilot');

  final ApiClient _client;
  final AuthSession _auth;

  @override
  final LocalUiStore localUiStore;

  @override
  final UiAccount uiAccount;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _client;

  @override
  AuthSession get authSession => _auth;

  @override
  Future<void> close() async => _client.close();
}
