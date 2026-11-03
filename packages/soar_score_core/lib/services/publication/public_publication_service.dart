import '../../enums/publication_visibility.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/forbidden_error.dart';
import '../../models/id.dart';
import '../../models/publication/publication_identity.dart';
import '../../models/publication/publication_participant.dart';
import '../../models/publication/publication_projection.dart';
import '../../repositories/publication_identity_repository.dart';
import '../../repositories/repository.dart';
import '../../enums/lifecycle_state.dart';
import '../contest_activity.dart';
import 'public_publication.dart';

/// What anyone may read about published contests, without an account.
///
/// A Public or Unlisted publication is readable by its id; only Public ones
/// are listed. A Delisted or unknown publication is not found. The service
/// applies results hiding, so withheld standings never reach a client.
///
/// Hosted server only: publications are backend only data.
class PublicPublicationService {
  PublicPublicationService(this.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The code of the [ForbiddenError] for a publication that exists but is
  /// not shown.
  static const notVisibleCode = 'contest_not_visible';

  static ForbiddenError _notVisible() => ForbiddenError(
    notVisibleCode,
    'this contest is pending or private and is not shown',
  );

  /// The most a listing returns in one call.
  static const maxListLimit = 100;

  final Repository repository;
  final DateTime Function() _clock;

  /// The current projection of [publicationId].
  ///
  /// Throws an [EntityNotFoundError] when the publication does not exist, and
  /// a [ForbiddenError] with [notVisibleCode] when it exists but is not shown:
  /// Delisted (private), or with no projection yet (pending). The error
  /// carries nothing about the contest (#463).
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
      contest: (await _contestsWithStatus([(identity, projection)])).single,
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

  /// The Public publications, by contest start, newest first, with the
  /// number of contests in the time frame: those the [from] and [to] bounds
  /// list when either is given, otherwise the contests flown in the last 30
  /// days through the coming Sunday. The name and venue filters do not change
  /// that count.
  ///
  /// [name] and [venue] match case-insensitively as substrings. [from] and
  /// [to] bound the contest start day (UTC, inclusive). Without a [to], only
  /// contests starting through the coming Sunday are listed; on a Sunday that
  /// is the following Sunday. [today] is the caller's calendar day (default:
  /// today in UTC, and never more than a day from it) and fixes both the
  /// coming Sunday and the 30-day window.
  /// [limit] is capped at [maxListLimit]. Throws an [ArgumentError] for a
  /// non-positive [limit], a negative [offset] or a [from] after [to].
  Future<PublicPublicationList> list({
    String name = '',
    String venue = '',
    DateTime? from,
    DateTime? to,
    DateTime? today,
    int limit = 50,
    int offset = 0,
  }) async {
    if (limit < 1) throw ArgumentError.value(limit, 'limit', 'must be > 0');
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
    final fromDay = from == null ? null : _day(from);
    final toDay = to == null ? null : _day(to);
    if (fromDay != null && toDay != null && fromDay.isAfter(toDay)) {
      throw ArgumentError.value(from, 'from', 'must not be after to');
    }
    // A caller's day may be a time zone away from the server's, never more;
    // anything further would only lift the cap.
    final serverDay = _day(_clock());
    final day = today == null
        ? serverDay
        : _day(today).isBefore(serverDay.subtract(const Duration(days: 1)))
        ? serverDay.subtract(const Duration(days: 1))
        : _day(today).isAfter(serverDay.add(const Duration(days: 1)))
        ? serverDay.add(const Duration(days: 1))
        : _day(today);
    final startsBefore =
        toDay?.add(const Duration(days: 1)) ??
        day.add(Duration(days: 7 - (day.weekday % 7) + 1));
    final identityRepository = repository.publicationIdentityRepository;
    final (identities, recent) = await (
      identityRepository.listPublic(
        PublicationListQuery(
          name: name,
          venue: venue,
          startsOnOrAfter: fromDay,
          startsBefore: startsBefore,
          limit: limit.clamp(1, maxListLimit),
          offset: offset,
        ),
      ),
      // The count answers for the list's time frame: with a date filter the
      // same start-date bounds as the list; without one, contests flown in
      // the last 30 days, through the coming Sunday.
      identityRepository.countPublicActive(
        startsOnOrAfter: fromDay,
        endsOnOrAfter: fromDay == null && toDay == null
            ? day.subtract(const Duration(days: 30))
            : null,
        startsBefore: startsBefore,
      ),
    ).wait;
    // One read for the whole page, not one per row.
    final projections = await repository.publicationProjectionRepository
        .findByIds([
          for (final identity in identities)
            if (identity.currentProjectionId != null)
              identity.currentProjectionId!,
        ]);
    final listed = [
      for (final identity in identities)
        if (projections[identity.currentProjectionId] != null)
          (identity, projections[identity.currentProjectionId]!),
    ];
    final contests = await _contestsWithStatus(listed);
    final summaries = [
      for (var i = 0; i < listed.length; i++)
        PublicPublicationSummary(
          publicationId: listed[i].$1.id.value,
          publishedAt: listed[i].$1.publishedAt!,
          projectionRevision: listed[i].$2.projectionRevision,
          contest: contests[i],
          disciplineType: listed[i].$2.toJson()['discipline_type']! as String,
        ),
    ];
    return PublicPublicationList(publications: summaries, recentCount: recent);
  }

  /// The projection's contest identity with the `status` to show for each of
  /// [items]: `upcoming`, `in_progress` or `completed` (#454).
  ///
  /// Worked out now, never stored. The lifecycle state, start and last
  /// activity come from the live contest on this server; the values captured
  /// in the projection stand in when it has none (a manually updated
  /// publication whose contest is not here, or has no activity yet). The live
  /// facts of all [items] are read together, so a page costs the same few
  /// queries however many contests it lists.
  Future<List<Map<String, Object?>>> _contestsWithStatus(
    List<(PublicationIdentity, PublicationProjection)> items,
  ) async {
    if (items.isEmpty) return const [];
    final contestIds = [
      for (final (identity, _) in items)
        if (identity.contestId != null) identity.contestId!,
    ];
    final (live, activity) = await (
      repository.contestRepository.findByIds(contestIds),
      ContestActivity(repository).lastActivityAtFor(contestIds),
    ).wait;
    final now = _clock();
    return [
      for (final (identity, projection) in items)
        () {
          final captured = projection.contestIdentity;
          final contest = live[identity.contestId];
          final lifecycleState =
              contest?.lifecycleState ??
              _lifecycleNamed(
                captured['lifecycle_state'] ?? captured['status'],
              ) ??
              LifecycleState.running;
          return {
            ...captured,
            'status': contestDisplayStatus(
              lifecycleState: lifecycleState,
              startsAt:
                  contest?.startDateTime ??
                  DateTime.tryParse('${captured['start'] ?? ''}') ??
                  projection.publishedAt,
              // A live contest is authoritative, even with no activity (the
              // clock then runs from its start). The projection's value
              // stands in only when the contest is not on this server.
              lastActivityAt: contest == null
                  ? DateTime.tryParse('${captured['last_activity_at'] ?? ''}')
                  : activity[contest.id],
              now: now,
            ).wireName,
          };
        }(),
    ];
  }

  static LifecycleState? _lifecycleNamed(Object? name) {
    for (final state in LifecycleState.values) {
      if (state.name == '$name'.toLowerCase()) return state;
    }
    return null;
  }

  static DateTime _day(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
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
    if (identity == null) {
      throw EntityNotFoundError(
        entityType: 'Publication',
        entityId: publicationId,
      );
    }
    if (identity.visibility == PublicationVisibility.delisted) {
      throw _notVisible();
    }
    return identity;
  }

  Future<PublicationProjection> _current(PublicationIdentity identity) async {
    final projection = await _currentOrNull(identity);
    if (projection == null) throw _notVisible();
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
