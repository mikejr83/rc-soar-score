import '../../enums/audit_action.dart';
import '../../enums/authority.dart';
import '../../enums/delist_state.dart';
import '../../enums/delist_trigger.dart';
import '../../enums/publication_visibility.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/forbidden_error.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/publication/delist_request.dart';
import '../../models/publication/publication_identity.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/repository.dart';

/// The result of asking to delist a publication.
class DelistRequestResult {
  const DelistRequestResult({required this.request, required this.created});

  final DelistRequest request;

  /// False when a request was already pending and nothing was added.
  final bool created;
}

/// The director's side of delisting: ask for it, read the request, and
/// withdraw it while it is pending.
///
/// A system administrator decides a request; that flow is not here. It plugs
/// in by saving the request as approved or denied (and, when approved,
/// moving the publication to `Delisted`), recording `DelistDecided`.
///
/// Nothing about the contest or the publication changes while a request is
/// pending. Hosted server only.
class DelistRequestService {
  DelistRequestService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Asks to remove the publication of [contestId] from public view.
  ///
  /// Repeating the request while one is pending returns that request and
  /// records nothing. Throws an [EntityNotFoundError] for an unknown contest
  /// or a contest never published, a [ForbiddenError] for anyone but the
  /// director, and a [ContestStateError] (`publication_delisted`) when the
  /// publication is already delisted.
  Future<DelistRequestResult> request(
    Id contestId, {
    required Id actorId,
    required Authority authority,
    String? reason,
  }) async {
    final (_, identity) = await _load(contestId, actorId, authority);
    final pending = await repository.delistRequestRepository
        .findPendingForPublication(identity.id);
    if (pending != null) {
      return DelistRequestResult(request: pending, created: false);
    }
    if (identity.visibility == PublicationVisibility.delisted) {
      throw ContestStateError(
        'publication_delisted',
        'the publication is already delisted',
      );
    }
    final trimmed = reason?.trim();
    final draft = DelistRequest(
      id: _newId(),
      publicationId: identity.id,
      requestedBy: actorId,
      trigger: DelistTrigger.ownerRequest,
      reason: trimmed == null || trimmed.isEmpty ? null : trimmed,
      requestedAt: _clock(),
    );
    final stored = await repository.delistRequestRepository.createPending(
      draft,
      _event(
        AuditAction.delistRequested,
        draft,
        actorId: actorId,
        authority: authority,
      ),
    );
    return DelistRequestResult(
      request: stored.request,
      created: stored.created,
    );
  }

  /// The most recent delist request of the publication, whatever its state.
  ///
  /// Throws an [EntityNotFoundError] when the contest was never published or
  /// has no request, and a [ForbiddenError] for anyone but the director.
  Future<DelistRequest> current(
    Id contestId, {
    required Id actorId,
    required Authority authority,
  }) async {
    final (_, identity) = await _load(contestId, actorId, authority);
    final latest = await repository.delistRequestRepository
        .findLatestForPublication(identity.id);
    if (latest == null) {
      throw EntityNotFoundError(
        entityType: 'DelistRequest',
        entityId: identity.id,
      );
    }
    return latest;
  }

  /// Withdraws the pending request. Throws an [EntityNotFoundError] when
  /// none is pending.
  Future<DelistRequest> withdraw(
    Id contestId, {
    required Id actorId,
    required Authority authority,
  }) async {
    final (_, identity) = await _load(contestId, actorId, authority);
    final pending = await repository.delistRequestRepository
        .findPendingForPublication(identity.id);
    if (pending == null) {
      throw EntityNotFoundError(
        entityType: 'DelistRequest',
        entityId: identity.id,
      );
    }
    final withdrawn = DelistRequest(
      id: pending.id,
      publicationId: pending.publicationId,
      requestedBy: pending.requestedBy,
      trigger: pending.trigger,
      reason: pending.reason,
      requestedAt: pending.requestedAt,
      state: DelistState.withdrawn,
    );
    return repository.delistRequestRepository.saveWithAudit(
      withdrawn,
      _event(
        AuditAction.delistWithdrawn,
        withdrawn,
        actorId: actorId,
        authority: authority,
      ),
    );
  }

  Future<(Contest, PublicationIdentity)> _load(
    Id contestId,
    Id actorId,
    Authority authority,
  ) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    if (authority != Authority.director || contest.ownerAccountId != actorId) {
      throw ForbiddenError('not_director', 'only the contest director may');
    }
    final identity = await repository.publicationIdentityRepository
        .findForContest(contestId);
    if (identity == null) {
      throw EntityNotFoundError(
        entityType: 'PublicationIdentity',
        entityId: contestId,
      );
    }
    return (contest, identity);
  }

  AuditEvent _event(
    AuditAction action,
    DelistRequest request, {
    required Id actorId,
    required Authority authority,
  }) => AuditEvent(
    id: _newId(),
    entityType: 'DelistRequest',
    entityId: request.id,
    publicationId: request.publicationId,
    action: action,
    actorId: actorId,
    authority: authority,
    serverTimestamp: _clock(),
    reason: request.reason,
  );
}
