import '../../enums/publication_visibility.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/id.dart';
import '../../models/publication/publication_identity.dart';
import '../../models/publication/publication_participant.dart';
import '../../models/publication/publication_projection.dart';
import '../../repositories/repository.dart';
import 'public_publication.dart';

/// What anyone may read about published contests, without an account.
///
/// A Public or Unlisted publication is readable by its id; only Public ones
/// are listed. A Delisted or unknown publication is not found. The service
/// applies results hiding, so withheld standings never reach a client.
///
/// Hosted server only: publications are backend only data.
class PublicPublicationService {
  PublicPublicationService(this.repository);

  /// The most a listing returns in one call.
  static const maxListLimit = 100;

  final Repository repository;

  /// The current projection of [publicationId].
  ///
  /// Throws an [EntityNotFoundError] when the publication does not exist, is
  /// Delisted, or has no projection.
  Future<PublicPublication> read(Id publicationId) async {
    final identity = await _readable(publicationId);
    final projection = await _current(identity);
    final rows = {
      for (final row
          in await repository.publicationParticipantRepository
              .listForPublication(identity.id))
        row.pilotKey: row,
    };
    final hiddenThrough = identity.resultsHiddenThroughRound;
    final json = projection.toJson();
    return PublicPublication(
      publicationId: identity.id.value,
      visibility: identity.toJson()['visibility']! as String,
      projectionRevision: projection.projectionRevision,
      publishedAt: projection.publishedAt,
      contest: projection.contestIdentity,
      disciplineType: json['discipline_type']! as String,
      calculationVersion: projection.calculationVersion,
      resultsHiddenThroughRound: hiddenThrough,
      participants: [
        for (final entry in projection.participants ?? const <Object?>[])
          _participant(entry! as Map<String, Object?>, rows),
      ],
      teams: projection.teams ?? const [],
      matrix: projection.matrixInfo,
      scores: projection.scores ?? const [],
      standingRounds: _standingRounds(projection, hiddenThrough),
      calculation: projection.calculationMetadata,
    );
  }

  /// The Public publications, newest first.
  ///
  /// [limit] is capped at [maxListLimit]. Throws an [ArgumentError] for a
  /// non-positive [limit] or a negative [offset].
  Future<List<PublicPublicationSummary>> list({
    int limit = 50,
    int offset = 0,
  }) async {
    if (limit < 1) throw ArgumentError.value(limit, 'limit', 'must be > 0');
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
    final summaries = <PublicPublicationSummary>[];
    final identities = await repository.publicationIdentityRepository
        .listPublic();
    for (final identity in identities.skip(offset)) {
      if (summaries.length == limit.clamp(1, maxListLimit)) break;
      final projection = await _currentOrNull(identity);
      if (projection == null) continue;
      summaries.add(
        PublicPublicationSummary(
          publicationId: identity.id.value,
          publishedAt: identity.publishedAt!,
          projectionRevision: projection.projectionRevision,
          contest: projection.contestIdentity,
          disciplineType: projection.toJson()['discipline_type']! as String,
        ),
      );
    }
    return summaries;
  }

  /// The pilot's display entry with the identifying details from its
  /// participant row, or `details: null` once redacted (or missing).
  Map<String, Object?> _participant(
    Map<String, Object?> entry,
    Map<String, PublicationParticipant> rows,
  ) {
    final row = rows[entry['pilot_key']];
    return {
      ...entry,
      'details': row == null || row.isRedacted ? null : row.details,
    };
  }

  /// The standings of the rounds the director has not hidden.
  List<Object?> _standingRounds(
    PublicationProjection projection,
    int? hiddenThrough,
  ) => [
    for (final round
        in (projection.standings?['rounds'] as List<Object?>?) ?? const [])
      if (hiddenThrough == null ||
          ((round! as Map<String, Object?>)['as_of_round']! as int) <=
              hiddenThrough)
        round,
  ];

  Future<PublicationIdentity> _readable(Id publicationId) async {
    final identity = await repository.publicationIdentityRepository.findById(
      publicationId,
    );
    if (identity == null ||
        identity.visibility == PublicationVisibility.delisted) {
      throw EntityNotFoundError(
        entityType: 'Publication',
        entityId: publicationId,
      );
    }
    return identity;
  }

  Future<PublicationProjection> _current(PublicationIdentity identity) async {
    final projection = await _currentOrNull(identity);
    if (projection == null) {
      throw EntityNotFoundError(
        entityType: 'Publication',
        entityId: identity.id,
      );
    }
    return projection;
  }

  Future<PublicationProjection?> _currentOrNull(
    PublicationIdentity identity,
  ) async {
    final id = identity.currentProjectionId;
    return id == null
        ? null
        : repository.publicationProjectionRepository.findById(id);
  }
}
