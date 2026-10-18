import 'package:flutter/foundation.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../server/embedded_server.dart';
import 'auth_epoch.dart';

/// Which account the app acts as, tied to the sign-in that made it so.
///
/// Starts as the installation's Local account. [actAs] switches to the
/// signed-in account once the Local account is claimed, but only for the
/// sign-in the claim was made under; [actAsLocal] goes back when the director
/// signs out. [leaseFor] gives the number of the sign-in a request about
/// that account's data may be sent under, or `null` when it may not be sent.
class ActingAccount extends ChangeNotifier {
  ActingAccount(this._server, this._epoch);

  final EmbeddedServer _server;
  final AuthEpoch _epoch;
  int _boundEpoch = -1;

  core.Id get localAccountId => _server.localAccountId;

  /// The account requests act as now.
  core.Id get id => _server.actingAccountId;

  /// Whether the app acts as a signed-in account, not the Local one.
  bool get isAccount => id != localAccountId;

  /// Acts as [accountId] if sign-in [epoch] is still the current one;
  /// otherwise changes nothing and returns false.
  bool actAs(core.Id accountId, {required int epoch}) {
    if (!_epoch.isCurrent(epoch)) return false;
    _server.actAs(accountId);
    _boundEpoch = epoch;
    notifyListeners();
    return true;
  }

  void actAsLocal() {
    _server.actAsLocal();
    _boundEpoch = -1;
    notifyListeners();
  }

  /// The sign-in a request about [owner]'s data may be sent under, or `null`.
  int? leaseFor(core.Id owner) => isAccount && owner == id ? lease() : null;

  /// The sign-in a request that carries no account's data may be sent under
  /// (version check, installation, system data), or `null` when nobody is
  /// signed in as the acting account.
  int? lease() =>
      isAccount && _epoch.isCurrent(_boundEpoch) ? _boundEpoch : null;

  AuthEpoch get epoch => _epoch;
}
