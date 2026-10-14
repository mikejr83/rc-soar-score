import '../../enums/activation_kind.dart';
import '../../enums/audit_action.dart';
import '../../enums/authority.dart';
import '../../enums/platform.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/forbidden_error.dart';
import '../../errors/sync_refusal.dart';
import '../../models/id.dart';
import '../../models/sync/audit_event.dart';
import '../../models/sync/installation.dart';
import '../../models/sync/installation_activation.dart';
import '../../repositories/repository.dart';
import '../../repositories/sync_acceptor_store.dart';
import '../../repositories/sync_scope_key.dart';

/// Registers, lists and revokes a director's installations, and makes one of
/// them the administration installation of a contest.
class InstallationSyncService {
  InstallationSyncService(
    Repository repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _repository = repository,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _newId = newId ?? Id.create;

  final Repository _repository;

  // Read on first use, so building the service does not touch the store.
  late final SyncAcceptorStore _store = _repository.syncAcceptorStore;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Registers [id] for [accountId].
  ///
  /// Registering the same id again returns the stored row, revoked or not.
  /// Throws a [ForbiddenError] when another account owns the id.
  Future<Installation> register({
    required Id accountId,
    required Id id,
    required String label,
    required Platform platform,
  }) => _store.transaction((tx) async {
    final stored = await tx.findInstallation(id);
    if (stored != null) {
      _requireOwner(stored, accountId);
      return stored;
    }
    return tx.saveInstallation(
      Installation(
        id: id,
        ownerAccountId: accountId,
        label: label,
        platform: platform,
        createdAt: _clock(),
      ),
    );
  });

  Future<List<Installation>> list(Id accountId) =>
      _store.transaction((tx) => tx.listInstallations(accountId));

  /// Revokes [id]; revoking a revoked installation changes nothing.
  ///
  /// Throws an [EntityNotFoundError] for an unknown id and a [ForbiddenError]
  /// when another account owns it.
  Future<Installation> revoke({required Id accountId, required Id id}) =>
      _store.transaction((tx) async {
        final stored = await _requireInstallation(tx, id);
        _requireOwner(stored, accountId);
        if (stored.revokedAt != null) return stored;
        return tx.saveInstallation(
          Installation(
            id: stored.id,
            ownerAccountId: stored.ownerAccountId,
            label: stored.label,
            platform: stored.platform,
            createdAt: stored.createdAt,
            lastSeenAt: stored.lastSeenAt,
            lastSyncAt: stored.lastSyncAt,
            systemDataSeq: stored.systemDataSeq,
            revokedAt: _clock(),
          ),
        );
      });

  /// Makes [installationId] the administration installation of [contestId].
  ///
  /// In one transaction the previous open activation ends and the new one is
  /// created, so a contest never has two open activations. Activating the
  /// installation that already holds authority returns that activation. A
  /// `Reclaim` needs the installation to have pulled the contest's current
  /// sequence and to have no conflict waiting for a decision; otherwise it
  /// throws a [SyncRefusal] with `reclaim_requires_sync`.
  ///
  /// Throws an [EntityNotFoundError] for an unknown contest or installation
  /// and a [ForbiddenError] unless [accountId] owns both.
  Future<InstallationActivation> activate({
    required Id accountId,
    required Id contestId,
    required Id installationId,
    required ActivationKind kind,
  }) => _store.transaction((tx) async {
    final contest = await tx.findEntity('Contest', contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    if (contest['owner_account_id'] != accountId.value) {
      throw ForbiddenError(
        'not_director',
        'only the contest director activates an installation',
      );
    }
    final installation = await _requireInstallation(tx, installationId);
    _requireOwner(installation, accountId);
    if (installation.revokedAt != null) {
      throw SyncRefusal(
        'inactive_installation',
        403,
        'The installation was revoked and cannot hold a contest.',
      );
    }

    final open = [
      for (final a in await tx.listActivations(contestId))
        if (a.isOpen) a,
    ];
    final current = open.where((a) => a.installationId == installationId);
    if (current.isNotEmpty) return current.first;

    final scope = ContestScopeKey(contestId);
    if (kind == ActivationKind.reclaim) {
      final cursor = await tx.findCursor(installationId, scope);
      final pulled = cursor?.lastSyncedSequence ?? 0;
      final behind = pulled < await tx.highestSequence(scope);
      final undecided = (await tx.conflictsNeedingAction(scope)).isNotEmpty;
      if (behind || undecided) {
        throw SyncRefusal(
          'reclaim_requires_sync',
          409,
          'Pull the contest and decide its open conflicts before '
              'reactivating this installation.',
        );
      }
    }

    final now = _clock();
    for (final previous in open) {
      await tx.saveActivation(previous.close(now));
    }
    final activation = await tx.saveActivation(
      InstallationActivation(
        id: _newId(),
        contestId: contestId,
        installationId: installationId,
        activatedBy: accountId,
        kind: kind,
        activatedAt: now,
      ),
    );
    await tx.appendAudit(
      AuditEvent(
        id: _newId(),
        entityType: 'InstallationActivation',
        entityId: activation.id,
        contestId: contestId,
        action: AuditAction.installationActivation,
        actorId: accountId,
        authority: Authority.director,
        installationId: installationId,
        serverTimestamp: now,
        reason: kind.name,
      ),
    );
    return activation;
  });

  Future<Installation> _requireInstallation(
    SyncAcceptorTransaction tx,
    Id id,
  ) async =>
      await tx.findInstallation(id) ??
      (throw EntityNotFoundError(entityType: 'Installation', entityId: id));

  void _requireOwner(Installation installation, Id accountId) {
    if (installation.ownerAccountId != accountId) {
      throw ForbiddenError(
        'not_owner',
        'the installation belongs to another account',
      );
    }
  }
}
