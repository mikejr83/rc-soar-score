import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../auth/auth_session.dart';
import 'ui_account.dart';

/// The [UiAccount] of a build that has no local account (web): the signed-in
/// user's identity-provider id, or [localUiAccountId] while signed out.
final _logger = Logger('AuthUiAccount');

class AuthUiAccount extends ChangeNotifier
    implements UiAccount, AuditActorSource {
  AuthUiAccount(this._auth, {this.lookupActor}) : _id = _idFor(_auth) {
    _auth.addListener(_authChanged);
  }

  final AuthSession _auth;

  /// Asks the service for the account id the audit trail records.
  final Future<String?> Function()? lookupActor;
  String _id;
  String? _actorId;
  int _lookups = 0;

  static String _idFor(AuthSession auth) {
    final subject = auth.subject;
    return auth.isSignedIn && subject != null && subject.isNotEmpty
        ? 'user:$subject'
        : localUiAccountId;
  }

  @override
  String get id => _id;

  /// The account id the audit trail records for the signed-in user: not the
  /// sign-in subject [id] is made of. Known after [refreshActor] answers.
  @override
  String? get auditActorId => _actorId;

  /// Asks the service which account the signed-in user acts as. A failed
  /// lookup leaves the id unknown (the activity lists then call every actor
  /// by its account id instead of "You").
  Future<void> refreshActor() async {
    final lookup = lookupActor;
    final lookups = ++_lookups;
    String? actor;
    if (lookup != null && _auth.isSignedIn) {
      try {
        actor = await lookup();
      } on Object catch (error) {
        _logger.warning('Could not look up the account id', error);
      }
    }
    if (lookups != _lookups || actor == _actorId) return;
    _actorId = actor;
    notifyListeners();
  }

  void _authChanged() {
    final id = _idFor(_auth);
    if (id == _id) return;
    _id = id;
    _actorId = null;
    notifyListeners();
    // A user who signed in without a page reload needs the id too.
    unawaited(refreshActor());
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
