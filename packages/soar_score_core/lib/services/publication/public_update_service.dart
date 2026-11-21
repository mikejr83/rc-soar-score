import 'package:logging/logging.dart';

import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../../enums/lifecycle_state.dart';
import '../../enums/public_update_mode.dart';
import '../../errors/contest_state_error.dart';
import '../../models/contest/core_options.dart';
import '../../models/id.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/recorded_score.dart';
import '../../repositories/repository.dart';
import '../scores_service.dart';
import 'publication_service.dart';
import 'publication_view.dart';

final _logger = Logger('PublicUpdate');

/// Decides whether a score entry reaches the public projection, by the
/// contest's `public_update_mode`:
///
/// - Automatic: every entry publishes;
/// - RoundCompletion (the default): an entry publishes once its round has
///   every score entered, so a later correction in a complete round
///   publishes again;
/// - Manual: never; only the director publishes.
///
/// It never creates a publication: a contest that was never published, or is
/// delisted, is left alone. A failed publish is audited and thrown for the
/// caller to log; the score entry it follows is already stored.
class PublicUpdateService {
  PublicUpdateService(
    this.repository, {
    PublicationService? publication,
    ScoresService? scores,
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _publication = publication ?? PublicationService(repository),
       _scores = scores ?? ScoresService(repository),
       _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final PublicationService _publication;
  final ScoresService _scores;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Publishes after the score of [assignmentId] was entered, if the update
  /// mode calls for it. [entryMutationId] is the score entry's client
  /// mutation id, so a retried entry publishes once.
  ///
  /// Returns the publish, or null when the mode, the contest's publication
  /// state or an incomplete round says not to.
  Future<PublishResult?> afterScoreEntry(
    Id contestId, {
    required Id assignmentId,
    required String entryMutationId,
  }) async {
    final identity = await repository.publicationIdentityRepository
        .findForContest(contestId);
    if (identity == null) return null;
    final mode = await _modeOf(contestId);
    if (mode == null || mode == PublicUpdateMode.manual) return null;
    if (mode == PublicUpdateMode.roundCompletion &&
        !await _roundIsComplete(contestId, assignmentId)) {
      return null;
    }
    try {
      return await _publication.publishAutomatically(
        contestId,
        clientMutationId: 'auto-$entryMutationId',
      );
    } on ContestStateError {
      // Already audited as refused by the publication service.
      rethrow;
    } on Object {
      await _auditFailure(contestId, identity.id, entryMutationId);
      rethrow;
    }
  }

  /// Publishes after the contest was completed, so the public projection
  /// carries the Completed status. [revision] is the completed contest's
  /// revision, so a retried request publishes once.
  ///
  /// Whatever the update mode except Manual publishes: completing is the end
  /// of the last round. Returns null when the mode or the contest's
  /// publication state says not to.
  Future<PublishResult?> afterCompletion(
    Id contestId, {
    required int revision,
  }) async {
    final identity = await repository.publicationIdentityRepository
        .findForContest(contestId);
    if (identity == null) return null;
    final mode = await _modeOf(contestId);
    if (mode == null || mode == PublicUpdateMode.manual) return null;
    try {
      return await _publication.publishAutomatically(
        contestId,
        clientMutationId: 'auto-complete-$revision',
      );
    } on ContestStateError {
      rethrow;
    } on Object {
      await _auditFailure(contestId, identity.id, 'complete-$revision');
      rethrow;
    }
  }

  /// Entity types whose change alters what the public site shows.
  static const _publicTypes = {
    'Contest',
    'ContestParticipation',
    'Team',
    'TeamMembership',
    'Round',
    'RoundGroup',
    'ReFlight',
    'ReFlightParticipant',
    'ScorePlaceholder',
    'ContestConfigurationRevision',
    'MatrixRevision',
    'MatrixAssignment',
    'ScoreAttempt',
    'OfficialScore',
    promotionReceiptEntityType,
  };

  /// Entity types that carry a score change (a native score write queues
  /// the attempt, the official score and the placeholder together; Mark
  /// official arrives as a promotion), which the RoundCompletion mode holds
  /// back until the affected round is complete.
  static const _scoreTypes = {
    'ScoreAttempt',
    'OfficialScore',
    'ScorePlaceholder',
    promotionReceiptEntityType,
  };

  /// Publishes after a sync exchange accepted changes of [entityTypes], so a
  /// change made in the app reaches the public site without a manual publish:
  /// a configuration change such as dropped rounds, a roster or matrix edit,
  /// completing the contest, or scores.
  ///
  /// By the update mode: Automatic publishes for any such change;
  /// RoundCompletion for any change that is not only score changes, and for
  /// score changes once a round they touch is complete (the same rule as a
  /// score entry through the API); Manual never. [assignmentIds] are the
  /// matrix assignments the accepted score changes belong to. A `Contest`
  /// change that comes with score changes is their companion (a score write
  /// saves the contest too) and counts as one, unless the contest is
  /// Completed, which is the end of the last round and always publishes.
  ///
  /// It never creates a publication. [exchangeMutationId] (the last accepted
  /// mutation of the exchange) makes a retried exchange publish once.
  ///
  /// Returns the publish, or null when the mode, the entity types or the
  /// contest's publication state say not to. A failed publish is audited and
  /// thrown for the caller to log; the accepted changes are already stored.
  Future<PublishResult?> afterSync(
    Id contestId, {
    required Set<String> entityTypes,
    Set<Id> assignmentIds = const {},
    required String exchangeMutationId,
  }) async {
    final changed = entityTypes.intersection(_publicTypes);
    if (changed.isEmpty) return null;
    final identity = await repository.publicationIdentityRepository
        .findForContest(contestId);
    if (identity == null) return null;
    final mode = await _modeOf(contestId);
    if (mode == null || mode == PublicUpdateMode.manual) return null;
    if (mode == PublicUpdateMode.roundCompletion &&
        !await _worthPublishing(contestId, changed, assignmentIds)) {
      return null;
    }
    try {
      return await _publication.publishAutomatically(
        contestId,
        clientMutationId: 'auto-sync-$exchangeMutationId',
      );
    } on ContestStateError {
      rethrow;
    } on Object {
      await _auditFailure(contestId, identity.id, 'sync-$exchangeMutationId');
      rethrow;
    }
  }

  /// RoundCompletion's rule for a synced batch of [changed] types.
  Future<bool> _worthPublishing(
    Id contestId,
    Set<String> changed,
    Set<Id> assignmentIds,
  ) async {
    final others = changed.difference({..._scoreTypes, 'Contest'});
    if (others.isNotEmpty) return true;
    final scoreChanged = changed.intersection(_scoreTypes).isNotEmpty;
    if (!scoreChanged) return true; // only the contest itself changed
    final contest = await repository.contestRepository.findById(contestId);
    if (contest?.lifecycleState == LifecycleState.completed) return true;
    final roundIds = <Id>{};
    for (final id in assignmentIds) {
      final assignment = await repository.matrixAssignmentRepository.findById(
        id,
      );
      if (assignment != null) roundIds.add(assignment.scheduledRoundId);
    }
    if (roundIds.isEmpty) return false;
    final scores = await _scores.list(contestId);
    return scores.rounds.any(
      (round) => roundIds.contains(round.roundId) && round.isComplete,
    );
  }

  Future<PublicUpdateMode?> _modeOf(Id contestId) async {
    final revision = await repository.contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (revision == null) return null;
    return CoreOptions.fromMap(revision.config.core).publicUpdateMode;
  }

  Future<bool> _roundIsComplete(Id contestId, Id assignmentId) async {
    final assignment = await repository.matrixAssignmentRepository.findById(
      assignmentId,
    );
    if (assignment == null) return false;
    final scores = await _scores.list(contestId);
    return scores.rounds
        .where((round) => round.roundId == assignment.scheduledRoundId)
        .any((round) => round.isComplete);
  }

  /// An error that is not a refusal (the database, say) leaves no audit
  /// event of its own, so record it here. Best effort: a failing audit must
  /// not hide the original error.
  Future<void> _auditFailure(
    Id contestId,
    Id publicationId,
    String entryMutationId,
  ) async {
    try {
      await repository.auditEventRepository.append(
        AuditEvent(
          id: _newId(),
          entityType: 'PublicationIdentity',
          entityId: publicationId,
          publicationId: publicationId,
          action: AuditAction.publicationAttempt,
          authority: Authority.system,
          serverTimestamp: _clock(),
          reason: 'publish_failed',
          outcome: AuditOutcome.rejected,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Could not audit a failed automatic publish for $contestId',
        error,
        stackTrace,
      );
    }
  }
}
