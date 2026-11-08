import 'package:flutter/foundation.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../server/embedded_server.dart';
import '../server/profile_access.dart';
import 'auth_epoch.dart';
import 'sync_pin.dart';

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

  /// Whether the signed-in account is not the one this computer's data belongs
  /// to, so the data is not served (see `profileMismatchGuard`).
  bool get profileMismatch => _server.profileMismatch;

  /// Whether the claimed data may be served now.
  ProfileAccess get profileAccess => _server.profileAccess;

  /// A user signed in or was restored: the claimed data is served only when
  /// their identity [subject] is the one that claimed it.
  void signedIn(String? subject) {
    _server.profileSignedIn(subject);
    notifyListeners();
  }

  /// The Local data is about to be re-pointed to [accountId]: work begun
  /// earlier is stopped before it stores anything, and new work waits. Returns
  /// whether it brackets a change, which [claimFinished] then ends.
  bool claimStarting(core.Id accountId, String? subject) =>
      _server.beginClaim(accountId, subject);

  /// Ends what [claimStarting] began.
  void claimFinished() => _server.endClaim();

  /// A claim by [subject] committed, for whichever sign-in made it: the data
  /// belongs to [accountId] from now on. Only ownership changes; acting as the
  /// account (and any sync lease) still waits for [actAs] under a sign-in that
  /// is still current.
  void claimRecorded(core.Id accountId, String? subject) {
    _server.recordClaim(accountId, subject);
    notifyListeners();
  }

  /// The service refused sign-in [epoch]'s claim as another account's data:
  /// stops serving the data, unless that sign-in is no longer the current one.
  /// Returns whether it did. Signing out, or signing in as the owning account,
  /// ends it.
  bool markProfileMismatch({required int epoch}) {
    if (!_epoch.isCurrent(epoch)) return false;
    _server.markProfileMismatch();
    _boundEpoch = -1;
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

  /// The profile's state now (see `EmbeddedServer.profileGeneration`).
  int get profileGeneration => _server.profileGeneration;

  /// Runs [write] as an operation pinned to what a sync exchange depended on:
  /// the database refuses its statements and commit once the profile changed
  /// or the sign-in the exchange was sent under is no longer the one in
  /// force for its data.
  Future<T> runPinned<T>(SyncPin pin, Future<T> Function() write) =>
      _server.runPinnedOperation(
        write,
        generation: pin.generation,
        stillValid: () {
          final owner = pin.owner;
          final now = owner == null ? lease() : leaseFor(owner);
          if (now == null || now != pin.lease) {
            throw const ProfileUnavailableError.changed();
          }
        },
      );
}
