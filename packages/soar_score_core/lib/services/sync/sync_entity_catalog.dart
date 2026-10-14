import '../../models/shared/sync_scope.dart';

/// How an entity type changes over its life.
enum SyncEntityShape {
  /// Carries a `revision` the service bumps on each accepted change.
  revisioned,

  /// Written once and never changed.
  appendOnly,

  /// Replaced or deleted whole, with no revision (a landing table).
  unrevisioned,
}

/// What the acceptor knows about one entity type that may arrive in a
/// mutation.
class SyncEntityKind {
  const SyncEntityKind(this.entityType, this.scope, this.shape);

  final String entityType;

  /// `contest` or `director`.
  final SyncScope scope;
  final SyncEntityShape shape;

  /// The JSON key that names the entity's scope: the entity's own id for a
  /// contest, `contest_id` for the rest of a contest's data, and
  /// `owner_account_id` for a director's data.
  String get scopeKey => switch (entityType) {
    'Contest' => 'id',
    _ when scope == SyncScope.contest => 'contest_id',
    _ => 'owner_account_id',
  };
}

/// The entity types a sync mutation may change.
///
/// Derived values (`FlightResult`, `ParticipationStanding`, `TeamStanding`)
/// and system data are absent on purpose: the service recomputes the first and
/// ships the second, so a mutation naming them is refused.
abstract final class SyncEntityCatalog {
  static const _contest = SyncScope.contest;
  static const _director = SyncScope.director;

  static final Map<String, SyncEntityKind> _kinds = {
    for (final kind in const [
      SyncEntityKind('Contest', _contest, SyncEntityShape.revisioned),
      SyncEntityKind(
        'ContestParticipation',
        _contest,
        SyncEntityShape.revisioned,
      ),
      SyncEntityKind('Team', _contest, SyncEntityShape.revisioned),
      SyncEntityKind('TeamMembership', _contest, SyncEntityShape.revisioned),
      SyncEntityKind('ContestModelLink', _contest, SyncEntityShape.revisioned),
      SyncEntityKind('Round', _contest, SyncEntityShape.revisioned),
      SyncEntityKind('RoundGroup', _contest, SyncEntityShape.revisioned),
      SyncEntityKind('ReFlight', _contest, SyncEntityShape.revisioned),
      SyncEntityKind(
        'ReFlightParticipant',
        _contest,
        SyncEntityShape.revisioned,
      ),
      SyncEntityKind('ScorePlaceholder', _contest, SyncEntityShape.revisioned),
      SyncEntityKind('ReviewRequest', _contest, SyncEntityShape.revisioned),
      SyncEntityKind(
        'ContestConfigurationRevision',
        _contest,
        SyncEntityShape.appendOnly,
      ),
      SyncEntityKind('MatrixRevision', _contest, SyncEntityShape.appendOnly),
      SyncEntityKind('MatrixAssignment', _contest, SyncEntityShape.appendOnly),
      SyncEntityKind('ScoreAttempt', _contest, SyncEntityShape.appendOnly),
      SyncEntityKind('OfficialScore', _contest, SyncEntityShape.appendOnly),
      SyncEntityKind(
        'ParticipantProfile',
        _director,
        SyncEntityShape.revisioned,
      ),
      SyncEntityKind('Role', _director, SyncEntityShape.revisioned),
      SyncEntityKind('ModelCatalog', _director, SyncEntityShape.revisioned),
      SyncEntityKind(
        'ContestConfigurationPreset',
        _director,
        SyncEntityShape.revisioned,
      ),
      SyncEntityKind('LandingTable', _director, SyncEntityShape.unrevisioned),
    ])
      kind.entityType: kind,
  };

  /// The kind of [entityType], or null when a mutation may not name it.
  static SyncEntityKind? of(String entityType) => _kinds[entityType];

  /// Every entity type a mutation may name.
  static Iterable<SyncEntityKind> get all => _kinds.values;

  /// The types of contest data the director fixes with the draw, so a stale
  /// change to one is never merged field by field once the contest is past
  /// configuration.
  static const fixedAfterConfiguration = {
    'ContestParticipation',
    'Team',
    'TeamMembership',
    'ContestModelLink',
    'Role',
    'Round',
    'RoundGroup',
  };

  /// The entity type that carries a conflict to every installation.
  static const conflictRecordType = 'ConflictRecord';
}
