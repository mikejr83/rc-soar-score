import 'package:flutter/foundation.dart';

import '../../auth/auth_session.dart';
import 'ui_account.dart';

/// The [UiAccount] of a build that has no local account (web): the signed-in
/// user's identity-provider id, or [localUiAccountId] while signed out.
class AuthUiAccount extends ChangeNotifier implements UiAccount {
  AuthUiAccount(this._auth) : _id = _idFor(_auth) {
    _auth.addListener(_authChanged);
  }

  final AuthSession _auth;
  String _id;

  static String _idFor(AuthSession auth) {
    final subject = auth.subject;
    return auth.isSignedIn && subject != null && subject.isNotEmpty
        ? 'user:$subject'
        : localUiAccountId;
  }

  @override
  String get id => _id;

  void _authChanged() {
    final id = _idFor(_auth);
    if (id == _id) return;
    _id = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
