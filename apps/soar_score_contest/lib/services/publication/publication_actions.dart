import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('PublicationActions');

/// Why a publish or visibility change did not happen. The page words each in
/// its own language.
enum PublicationFailure {
  /// The contest changed since the director reviewed it (409
  /// `stale_source_revision`).
  staleContest,

  /// The results are out of date (409 `results_stale`).
  staleResults,

  /// The contest is not ready to publish (any other 409 on publish).
  notReady,

  /// The publication was delisted and cannot change (409).
  delisted,

  /// The server does not publish contests (409 `publishing_not_available`).
  unavailable,

  /// Delisting can only be requested for a Public publication (409
  /// `publication_not_public`).
  notPublic,

  /// There is no pending delisting request to withdraw (404).
  nothingPending,

  /// Only the contest's director may do this (403).
  notDirector,

  /// Nobody is signed in, so the hosted server refused the call (401).
  signInRequired,

  /// The hosted server does not have the contest yet: it has not synced (404
  /// on publish).
  notSynced,

  /// The server could not be reached.
  network,

  /// Anything else.
  other,
}

/// The result of a publish or visibility change: the publication as the
/// server now has it, or why it did not happen.
class PublicationOutcome {
  const PublicationOutcome.success(this.publication) : failure = null;
  const PublicationOutcome.failed(this.failure) : publication = null;

  /// Done, with nothing to show: a delisting request was made or withdrawn.
  const PublicationOutcome.done() : publication = null, failure = null;

  final Map<String, Object?>? publication;
  final PublicationFailure? failure;

  bool get succeeded => failure == null;
}

/// Publishes a contest and changes its visibility with the publication API.
class PublicationActions {
  PublicationActions(this.client);

  final ApiClient client;

  /// The mutation id of publishing [contest] on top of the copy numbered
  /// [projectionRevision] (0 when never published).
  ///
  /// It depends only on what the director saw, so retrying the same attempt
  /// after a lost response sends the same id and the server returns the copy
  /// it already made. Once the page has seen a new copy, or the contest has
  /// moved on, the id changes and the publish is a new update.
  static String mutationId(Contest contest, int projectionRevision) =>
      'publish-${contest.id.value}-c${contest.revision}-p$projectionRevision';

  /// Publishes [contest] as it is now. The revision sent is the one the
  /// director saw, so a contest that moved on is refused. [projectionRevision]
  /// is the latest copy the director saw, if any.
  Future<PublicationOutcome> publish(
    Contest contest, {
    int projectionRevision = 0,
  }) => _run(
    () async => PublicationOutcome.success(
      await client.publishContest(
        contest.id,
        PublishContestRequest(
          clientMutationId: mutationId(contest, projectionRevision),
          sourceContestRevision: contest.revision,
        ),
      ),
    ),
    forPublish: true,
  );

  /// Switches the publication of [contestId] to [visibility], which must be
  /// Unlisted or Public.
  Future<PublicationOutcome> setVisibility(
    Id contestId,
    PublicationVisibility visibility,
  ) {
    final name = switch (visibility) {
      PublicationVisibility.unlisted => 'Unlisted',
      PublicationVisibility.public => 'Public',
      PublicationVisibility.delisted => throw ArgumentError.value(
        visibility,
        'visibility',
        'can only be Unlisted or Public',
      ),
    };
    return _run(
      () async => PublicationOutcome.success(
        await client.setPublicationVisibility(
          contestId,
          SetVisibilityRequest(visibility: name),
        ),
      ),
      forPublish: false,
    );
  }

  /// Asks to delist the publication of [contestId]; [reason] is optional.
  /// Repeating it while a request is pending succeeds without a second one.
  Future<PublicationOutcome> requestDelisting(Id contestId, {String? reason}) =>
      _run(() async {
        await client.requestDelisting(contestId, reason: reason);
        return const PublicationOutcome.done();
      }, forPublish: false);

  /// Withdraws the pending delisting request of [contestId].
  Future<PublicationOutcome> withdrawDelisting(Id contestId) => _run(() async {
    await client.withdrawDelistRequest(contestId);
    return const PublicationOutcome.done();
  }, forPublish: false);

  Future<PublicationOutcome> _run(
    Future<PublicationOutcome> Function() call, {
    required bool forPublish,
  }) async {
    try {
      return await call();
    } on ApiHttpError catch (error) {
      return PublicationOutcome.failed(_classify(error, forPublish));
    } on ApiNetworkError {
      return const PublicationOutcome.failed(PublicationFailure.network);
    } on ApiException {
      return const PublicationOutcome.failed(PublicationFailure.other);
    } on Object catch (error, stack) {
      // Not a failure the API reports: a bug. The director still gets a
      // message, and the details go to the log.
      _logger.severe('Unexpected publication failure', error, stack);
      return const PublicationOutcome.failed(PublicationFailure.other);
    }
  }

  static PublicationFailure _classify(ApiHttpError error, bool forPublish) {
    if (error.statusCode == 401) {
      return PublicationFailure.signInRequired;
    }
    if (error.statusCode == 403) {
      return PublicationFailure.notDirector;
    }
    if (error.statusCode == 404) {
      return forPublish
          ? PublicationFailure.notSynced
          : PublicationFailure.nothingPending;
    }
    if (error.statusCode == 409) {
      return switch (error.error?.code) {
        'stale_source_revision' => PublicationFailure.staleContest,
        'results_stale' => PublicationFailure.staleResults,
        'publication_delisted' => PublicationFailure.delisted,
        'publication_not_public' => PublicationFailure.notPublic,
        'publishing_not_available' => PublicationFailure.unavailable,
        _ =>
          forPublish
              ? PublicationFailure.notReady
              : PublicationFailure.delisted,
      };
    }
    return PublicationFailure.other;
  }
}
