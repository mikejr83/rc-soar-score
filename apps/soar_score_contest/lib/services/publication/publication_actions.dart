import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

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

  /// Only the contest's director may do this (403).
  notDirector,

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

  final Map<String, Object?>? publication;
  final PublicationFailure? failure;

  bool get succeeded => failure == null;
}

/// Publishes a contest and changes its visibility with the publication API.
class PublicationActions {
  PublicationActions(this.client, {String Function()? newMutationId})
    : _newMutationId = newMutationId ?? (() => Id.create().value);

  final ApiClient client;
  final String Function() _newMutationId;

  /// Publishes [contest] as it is now. The revision sent is the one the
  /// director saw, so a contest that moved on is refused.
  Future<PublicationOutcome> publish(Contest contest) => _run(
    () async => PublicationOutcome.success(
      await client.publishContest(
        contest.id,
        PublishContestRequest(
          clientMutationId: _newMutationId(),
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
    } on Object {
      return const PublicationOutcome.failed(PublicationFailure.other);
    }
  }

  static PublicationFailure _classify(ApiHttpError error, bool forPublish) {
    if (error.statusCode == 403) {
      return PublicationFailure.notDirector;
    }
    if (error.statusCode == 409) {
      return switch (error.error?.code) {
        'stale_source_revision' => PublicationFailure.staleContest,
        'results_stale' => PublicationFailure.staleResults,
        'publication_delisted' => PublicationFailure.delisted,
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
