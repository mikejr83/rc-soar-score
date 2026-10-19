import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;

/// A [core.LocalAccountRepository] that records the re-pointing, and whose
/// `find` and `reassignTo` can be held to let a test change the sign-in while
/// they are pending.
class FakeLocalAccount implements core.LocalAccountRepository {
  FakeLocalAccount(this.id);

  core.Id? id;
  final reassigned = <core.Id>[];
  Object? reassignError;
  var storedPreferences = core.AccountPreferences();

  /// While set, `find` / `reassignTo` wait for it.
  Completer<void>? findGate;
  Completer<void>? reassignGate;

  @override
  Future<core.Id?> find() async {
    await findGate?.future;
    return id;
  }

  @override
  Future<core.Id> ensure() async => id ??= core.Id.create();

  @override
  Future<void> reassignTo(core.Id accountId) async {
    await reassignGate?.future;
    final error = reassignError;
    if (error != null) throw error;
    reassigned.add(accountId);
  }

  @override
  Future<core.AccountPreferences> preferences() async => storedPreferences;

  @override
  Future<void> savePreferences(core.AccountPreferences preferences) async =>
      storedPreferences = preferences;
}
