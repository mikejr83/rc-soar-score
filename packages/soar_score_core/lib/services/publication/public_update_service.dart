import 'package:logging/logging.dart';

import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../../enums/public_update_mode.dart';
import '../../errors/contest_state_error.dart';
import '../../models/contest/core_options.dart';
import '../../models/id.dart';
import '../../models/sync/audit_event.dart';
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
