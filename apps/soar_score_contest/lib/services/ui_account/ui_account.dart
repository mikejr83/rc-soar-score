import 'package:flutter/foundation.dart';

/// The `LocalUiStore` account id used when nobody is signed in (web) and in
/// builds without a bootstrap.
const String localUiAccountId = 'local';

/// Names the account whose UI-only state (theme, hidden panels, drafts) the
/// app reads and writes, and tells listeners when it changes.
///
/// The Local account counts: offline, [id] is the installation's Local account
/// id. Callers pass [id] to every `LocalUiStore` call and reload when this
/// notifies.
abstract class UiAccount implements Listenable {
  String get id;
}

/// A [UiAccount] that never changes: tests, and builds without a bootstrap.
class FixedUiAccount implements UiAccount {
  const FixedUiAccount([this.id = localUiAccountId]);

  @override
  final String id;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
