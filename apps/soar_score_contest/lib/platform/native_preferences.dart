import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;

import 'auth_epoch.dart';

/// The native build's way to read and keep the account's preferences.
///
/// Signed out, the installation's own copy (the Local account's row) is the
/// only one. Signed in, the account on the service holds the choices, so a
/// change is first stored there, bound to the sign-in that made it, and then
/// copied to the installation; if the upload fails the change is reported as
/// not saved, since the claim at the next sign-in lets the account's own
/// values stand over the installation's.
class NativePreferences {
  NativePreferences({
    required this._epoch,
    required this._local,
    required this._put,
    this.uploadTimeout = const Duration(seconds: 10),
  });

  final AuthEpoch _epoch;
  final core.LocalAccountRepository _local;
  final Future<core.AccountPreferences> Function(core.AccountPreferences) _put;

  /// How long to wait for the service before the change counts as not saved.
  final Duration uploadTimeout;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires when the installation's copy changed behind the app's back (the
  /// claim merged the account's preferences into it).
  Stream<void> get changes => _changes.stream;

  /// Tells listeners that the installation's copy changed.
  void changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<core.AccountPreferences> load() => _local.preferences();

  /// Stores [preferences]; throws if they could not be kept.
  Future<void> save(core.AccountPreferences preferences) async {
    final session = _epoch.value;
    if (_epoch.isCurrent(session)) {
      await _epoch.runBound(
        session,
        () => _put(preferences).timeout(uploadTimeout),
      );
      // The upload went to the account that made the change; the copy on this
      // installation belongs to whoever is signed in now.
      if (!_epoch.isCurrent(session)) throw SessionChangedError('preferences');
    }
    await _local.savePreferences(preferences);
  }

  Future<void> close() => _changes.close();
}
