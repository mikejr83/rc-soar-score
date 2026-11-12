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

/// A [UiAccount] whose UI storage id is not the account id the audit trail
/// records (web: the identity provider's subject versus the database account
/// id). [auditActorId] is the latter, `null` while signed out or not known.
abstract class AuditActorSource {
  String? get auditActorId;
}

extension UiAccountAuditActor on UiAccount {
  /// The id the audit trail records as this account's actor. For an account
  /// whose storage id is that id (native), [UiAccount.id].
  String? get auditActorId {
    final self = this;
    return self is AuditActorSource
        ? (self as AuditActorSource).auditActorId
        : id;
  }
}
