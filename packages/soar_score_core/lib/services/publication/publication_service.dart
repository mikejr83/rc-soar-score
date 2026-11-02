import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../../enums/claim_status.dart';
import '../../enums/publication_visibility.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/forbidden_error.dart';
import '../../models/accounts/account_public_profile.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/publication/publication_identity.dart';
import '../../models/shared/shared.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/repository.dart';
import 'publication_projection_builder.dart';
import 'publication_view.dart';

/// Publishes a contest and manages who can see the publication.
///
/// Only the contest's director publishes. The first publish creates an
/// Unlisted publication claimed by the director's public profile; later ones
/// add the next projection. Every attempt, successful or refused, leaves a
/// `PublicationAttempt` audit event, except a repeat of a request that
/// already succeeded, which changes and records nothing.
///
/// Hosted server only: publications are backend only data.
class PublicationService {
  PublicationService(
    this.repository, {
    PublicationProjectionBuilder? builder,
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create,
       _builder =
           builder ??
           PublicationProjectionBuilder(repository, clock: clock, newId: newId);

  final Repository repository;
  final PublicationProjectionBuilder _builder;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Publishes the current state of [contestId] as [actorId].
  ///
  /// [sourceContestRevision] is the contest revision the director saw; the
  /// publish is refused when the contest has moved on. Repeating a request
  /// with the same [clientMutationId] returns the projection it created.
  ///
  /// Throws an [EntityNotFoundError] for an unknown contest, a
  /// [ForbiddenError] when the caller is not the contest's director, and a
  /// [ContestStateError] for a stale source revision
  /// (`stale_source_revision`), a delisted publication
  /// (`publication_delisted`), or a contest that cannot be published yet.
  Future<PublishResult> publish(
    Id contestId, {
    required Id actorId,
    required Authority authority,
    required String clientMutationId,
    required int sourceContestRevision,
  }) async {
    if (clientMutationId.trim().isEmpty) {
      throw ArgumentError.value(clientMutationId, 'clientMutationId', 'blank');
    }
    if (sourceContestRevision < 0) {
      throw ArgumentError.value(
        sourceContestRevision,
        'sourceContestRevision',
        'must not be negative',
      );
    }
    final contest = await _requireContest(contestId);
    final existing = await repository.publicationIdentityRepository
        .findForContest(contestId);
    Future<Never> refuse(Object error, String code) => _refuse(
      error,
      code,
      contest: contest,
      existing: existing,
      actorId: actorId,
      authority: authority,
      sourceRevision: sourceContestRevision,
    );

    if (!_isDirector(contest, actorId, authority)) {
      await refuse(
        ForbiddenError('not_director', 'only the contest director publishes'),
        'not_director',
      );
    }
    if (existing != null) {
      final prior = await repository.publicationProjectionRepository
          .findByClientMutationId(existing.id, clientMutationId);
      if (prior != null) {
        return PublishResult(
          view: PublicationView(identity: existing, current: prior),
          created: false,
        );
      }
      if (existing.visibility == PublicationVisibility.delisted) {
        await refuse(
          ContestStateError(
            'publication_delisted',
            'a delisted publication cannot be republished',
          ),
          'publication_delisted',
        );
      }
    }
    if (contest.revision != sourceContestRevision) {
      await refuse(
        ContestStateError(
          'stale_source_revision',
          'the contest changed since revision $sourceContestRevision; '
              'review it and publish again',
        ),
        'stale_source_revision',
      );
    }

    final profile = await _profileOf(actorId);
    if (existing != null && existing.ownerPublicProfileId != profile.id) {
      await refuse(
        ForbiddenError('not_owner', 'the publication belongs to someone else'),
        'not_owner',
      );
    }
    return _store(
      contest,
      existing,
      ownerProfileId: profile.id,
      actorId: actorId,
      authority: authority,
      publishedBy: actorId,
      clientMutationId: clientMutationId,
      sourceRevision: sourceContestRevision,
      refuse: refuse,
    );
  }

  /// Publishes the current state of an already published contest on behalf
  /// of its director's update mode, after a score entry.
  ///
  /// The system acts, not a person: the audit event has no actor and the
  /// system authority. The caller has checked the update mode. Repeating a
  /// [clientMutationId] returns the projection it created.
  ///
  /// Returns null when the contest was never published or is delisted: this
  /// path never creates a publication. Throws a [ContestStateError]
  /// (audited as refused) when the contest cannot be published right now,
  /// for example because its results are stale.
  Future<PublishResult?> publishAutomatically(
    Id contestId, {
    required String clientMutationId,
  }) async {
    final contest = await _requireContest(contestId);
    final existing = await repository.publicationIdentityRepository
        .findForContest(contestId);
    final owner = existing?.ownerPublicProfileId;
    if (existing == null ||
        owner == null ||
        existing.visibility == PublicationVisibility.delisted) {
      return null;
    }
    final prior = await repository.publicationProjectionRepository
        .findByClientMutationId(existing.id, clientMutationId);
    if (prior != null) {
      return PublishResult(
        view: PublicationView(identity: existing, current: prior),
        created: false,
      );
    }
    Future<Never> refuse(Object error, String code) => _refuse(
      error,
      code,
      contest: contest,
      existing: existing,
      actorId: null,
      authority: Authority.system,
      sourceRevision: contest.revision,
    );
    return _store(
      contest,
      existing,
      ownerProfileId: owner,
      actorId: null,
      authority: Authority.system,
      publishedBy: contest.ownerAccountId,
      clientMutationId: clientMutationId,
      sourceRevision: contest.revision,
      refuse: refuse,
    );
  }

  /// Builds the next projection and stores it with the identity, the
  /// participant rows and the success event, all or nothing.
  Future<PublishResult> _store(
    Contest contest,
    PublicationIdentity? existing, {
    required Id ownerProfileId,
    required Id? actorId,
    required Authority authority,
    required Id? publishedBy,
    required String clientMutationId,
    required int sourceRevision,
    required Future<Never> Function(Object error, String code) refuse,
  }) async {
    final publicationId = existing?.id ?? _newId();
    final latest = existing == null
        ? null
        : await repository.publicationProjectionRepository.latestForPublication(
            existing.id,
          );
    final now = _clock();
    final built = await _guardBuild(
      () => _builder.build(
        contestId: contest.id,
        publicationId: publicationId,
        projectionRevision: (latest?.projectionRevision ?? 0) + 1,
        clientMutationId: clientMutationId,
        publishedBy: publishedBy,
      ),
      refuse,
    );
    final identity = PublicationIdentity(
      id: publicationId,
      contestId: contest.id,
      ownerPublicProfileId: ownerProfileId,
      claimStatus: ClaimStatus.claimed,
      visibility: existing?.visibility ?? PublicationVisibility.unlisted,
      publishedAt: existing?.publishedAt ?? now,
      currentProjectionId: built.projection.id,
      resultsHiddenThroughRound: contest.resultsHiddenThroughRound,
      resultsHiddenAt: contest.resultsHiddenAt,
      contestName: _text(built.projection.contestIdentity['name']),
      contestStartsAt: _timestamp(built.projection.contestIdentity['start']),
      contestEndsAt: _timestamp(built.projection.contestIdentity['end']),
      venue: _venue(built.projection.contestIdentity),
      revision: existing?.revision ?? 0,
    );
    final stored = await repository.publicationPublisher.publish(
      identity: identity,
      participants: built.participants,
      projection: built.projection,
      attempt: _event(
        contest: contest,
        identity: identity,
        actorId: actorId,
        authority: authority,
        sourceRevision: sourceRevision,
        outcome: AuditOutcome.success,
        resultingRevision: built.projection.projectionRevision,
      ),
    );
    return PublishResult(
      view: PublicationView(identity: stored, current: built.projection),
      created: true,
    );
  }

  /// Records a refused attempt, then throws [error].
  Future<Never> _refuse(
    Object error,
    String code, {
    required Contest contest,
    required PublicationIdentity? existing,
    required Id? actorId,
    required Authority authority,
    required int sourceRevision,
  }) async {
    await _audit(
      contest: contest,
      identity: existing,
      actorId: actorId,
      authority: authority,
      sourceRevision: sourceRevision,
      outcome: AuditOutcome.rejected,
      reason: code,
    );
    throw error;
  }

  /// The publication of [contestId] as its director sees it.
  ///
  /// Throws an [EntityNotFoundError] when the contest or its publication
  /// does not exist, and a [ForbiddenError] for anyone but the director.
  Future<PublicationView> read(
    Id contestId, {
    required Id actorId,
    required Authority authority,
  }) async {
    final contest = await _requireContest(contestId);
    _requireDirector(contest, actorId, authority);
    final identity = await _requirePublication(contestId);
    return PublicationView(
      identity: identity,
      current: await repository.publicationProjectionRepository
          .latestForPublication(identity.id),
    );
  }

  /// Switches the publication between Unlisted and Public.
  ///
  /// The private contest is not touched. Throws an [ArgumentError] for any
  /// other visibility, and a [ContestStateError] (`publication_delisted`)
  /// when the publication is delisted: only a moderator moves it back.
  Future<PublicationView> setVisibility(
    Id contestId,
    PublicationVisibility visibility, {
    required Id actorId,
    required Authority authority,
  }) async {
    if (visibility == PublicationVisibility.delisted) {
      throw ArgumentError.value(
        visibility.name,
        'visibility',
        'must be Unlisted or Public',
      );
    }
    final contest = await _requireContest(contestId);
    _requireDirector(contest, actorId, authority);
    final identity = await _requirePublication(contestId);
    if (identity.visibility == PublicationVisibility.delisted) {
      throw ContestStateError(
        'publication_delisted',
        'a delisted publication cannot change visibility',
      );
    }
    final current = await repository.publicationProjectionRepository
        .latestForPublication(identity.id);
    if (identity.visibility == visibility) {
      return PublicationView(identity: identity, current: current);
    }
    final saved = await repository.publicationIdentityRepository.save(
      PublicationIdentity(
        id: identity.id,
        contestId: identity.contestId,
        ownerPublicProfileId: identity.ownerPublicProfileId,
        claimStatus: identity.claimStatus,
        verificationEmail: identity.verificationEmail,
        visibility: visibility,
        publishedAt: identity.publishedAt,
        currentProjectionId: identity.currentProjectionId,
        resultsHiddenThroughRound: identity.resultsHiddenThroughRound,
        resultsHiddenAt: identity.resultsHiddenAt,
        contestName: identity.contestName,
        contestStartsAt: identity.contestStartsAt,
        contestEndsAt: identity.contestEndsAt,
        venue: identity.venue,
        revision: identity.revision,
      ),
    );
    return PublicationView(identity: saved, current: current);
  }

  Future<T> _guardBuild<T>(
    Future<T> Function() build,
    Future<Never> Function(Object error, String code) refuse,
  ) async {
    try {
      return await build();
    } on ContestStateError catch (error) {
      return refuse(error, error.code);
    }
  }

  bool _isDirector(Contest contest, Id actorId, Authority authority) =>
      authority == Authority.director && contest.ownerAccountId == actorId;

  void _requireDirector(Contest contest, Id actorId, Authority authority) {
    if (!_isDirector(contest, actorId, authority)) {
      throw ForbiddenError('not_director', 'only the contest director may');
    }
  }

  /// The director's public profile, created from the account on first use.
  Future<AccountPublicProfile> _profileOf(Id accountId) async {
    final found = await repository.accountPublicProfileRepository
        .findForAccount(accountId);
    if (found != null) return found;
    final account = await repository.accountRepository.findById(accountId);
    if (account == null) {
      throw EntityNotFoundError(entityType: 'Account', entityId: accountId);
    }
    return repository.accountPublicProfileRepository.save(
      AccountPublicProfile(
        id: _newId(),
        accountId: accountId,
        displayName: '${account.firstName} ${account.lastName}',
        createdAt: _clock(),
      ),
    );
  }

  Future<void> _audit({
    required Contest contest,
    required PublicationIdentity? identity,
    required Id? actorId,
    required Authority authority,
    required int sourceRevision,
    required AuditOutcome outcome,
    String? reason,
  }) => repository.auditEventRepository.append(
    _event(
      contest: contest,
      identity: identity,
      actorId: actorId,
      authority: authority,
      sourceRevision: sourceRevision,
      outcome: outcome,
      reason: reason,
    ),
  );

  /// An attempt belongs to its publication once it has one, and to the
  /// contest before that.
  AuditEvent _event({
    required Contest contest,
    required PublicationIdentity? identity,
    required Id? actorId,
    required Authority authority,
    required int sourceRevision,
    required AuditOutcome outcome,
    int? resultingRevision,
    String? reason,
  }) => AuditEvent(
    id: _newId(),
    entityType: identity == null ? 'Contest' : 'PublicationIdentity',
    entityId: identity?.id ?? contest.id,
    contestId: identity == null ? contest.id : null,
    publicationId: identity?.id,
    action: AuditAction.publicationAttempt,
    actorId: actorId,
    authority: authority,
    baseRevision: sourceRevision,
    resultingRevision: resultingRevision,
    serverTimestamp: _clock(),
    reason: reason,
    outcome: outcome,
  );

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }

  Future<PublicationIdentity> _requirePublication(Id contestId) async {
    final identity = await repository.publicationIdentityRepository
        .findForContest(contestId);
    if (identity == null) {
      throw EntityNotFoundError(
        entityType: 'PublicationIdentity',
        entityId: contestId,
      );
    }
    return identity;
  }
}

String? _text(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}

DateTime? _timestamp(Object? value) {
  final text = _text(value);
  return text == null ? null : parseUtcTimestamp(text);
}

/// Host, city, state and country of a projection's contest identity,
/// whichever are set, joined with ", " (the form the listing searches).
String? _venue(Map<String, Object?> contest) {
  final parts = [
    for (final key in const ['host', 'city', 'state', 'country'])
      ?_text(contest[key]),
  ];
  return parts.isEmpty ? null : parts.join(', ');
}
