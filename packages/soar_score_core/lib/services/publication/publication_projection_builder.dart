import 'dart:math';

import '../../enums/lifecycle_state.dart';
import '../../enums/role_type.dart';
import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/contest/contest.dart';
import '../../models/discipline/discipline_score_field.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_revision.dart';
import '../../models/matrix/round.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/participants/participant_profile.dart';
import '../../models/publication/publication_participant.dart';
import '../../models/publication/publication_projection.dart';
import '../../models/results/participation_standing.dart';
import '../../models/results/team_standing.dart';
import '../../models/shared/shared.dart';
import '../../repositories/repository.dart';
import '../contest_activity.dart';
import '../results_service.dart';
import 'publication_build.dart';

/// Builds the public snapshot of a contest.
///
/// The projection holds no names or other private data: a pilot appears only
/// by an opaque `pilot_key`, and the identifying details go to the
/// [PublicationParticipant] row with that key. A pilot keeps the same key
/// across publishes of one publication.
///
/// The builder reads the stored results and never recalculates. It refuses a
/// contest whose results are stale, so a projection always matches the
/// scores. The builder stores nothing.
class PublicationProjectionBuilder {
  PublicationProjectionBuilder(
    this.repository, {
    ResultsService? results,
    DateTime Function()? clock,
    Id Function()? newId,
    String Function()? newPilotKey,
  }) : _results = results ?? ResultsService(repository),
       _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create,
       _newPilotKey = newPilotKey ?? _randomKey;

  final Repository repository;
  final ResultsService _results;
  final DateTime Function() _clock;
  final Id Function() _newId;
  final String Function() _newPilotKey;

  /// Builds revision [projectionRevision] of [publicationId] from the
  /// contest's current data.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist, and a
  /// [ContestStateError] when the contest has no configuration or finalized
  /// matrix (`nothing_to_publish`), or its results are stale
  /// (`results_stale`).
  Future<PublicationBuild> build({
    required Id contestId,
    required Id publicationId,
    required int projectionRevision,
    required String clientMutationId,
    Id? publishedBy,
  }) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    final config = await repository.contestConfigurationRevisionRepository
        .latestForContest(contestId);
    final matrix = await _currentMatrix(contestId);
    if (config == null || matrix == null) {
      throw ContestStateError(
        'nothing_to_publish',
        'the contest needs a configuration and a drawn matrix',
      );
    }
    final current = await _results.read(contestId);
    if (current.isStale) {
      throw ContestStateError(
        'results_stale',
        'the results are out of date; recalculate before publishing',
      );
    }
    final profile = await repository.disciplineProfileRepository.findById(
      config.disciplineProfileId,
    );
    if (profile == null) {
      throw EntityNotFoundError(
        entityType: 'DisciplineProfile',
        entityId: config.disciplineProfileId,
      );
    }

    final scoreFields = _publicScoreFields(profile.scoreFields);
    final pilots = await _pilots(contestId, publicationId);
    final keyOf = {for (final p in pilots) p.participation.id: p.key};
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where((round) => round.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final teams = await _teams(contestId, keyOf);

    final projection = PublicationProjection(
      id: _newId(),
      publicationId: publicationId,
      projectionRevision: projectionRevision,
      contestRevision: contest.revision,
      configRevision: config.revisionNumber,
      matrixRevision: matrix.revisionNumber,
      disciplineType: profile.profile.type,
      disciplineRulesVersion: profile.profile.version,
      calculationVersion: await _calculationVersion(contestId),
      contestIdentity: _identity(
        contest,
        profile.profile.name,
        await ContestActivity(repository).lastActivityAt(contestId),
      ),
      participants: [for (final p in pilots) p.entry(teams.keyByPilot[p.key])],
      teams: teams.entries,
      matrixInfo: await _matrixInfo(matrix, rounds, keyOf),
      scores: await _scores(contestId, rounds, keyOf, scoreFields),
      standings: await _standings(contestId, keyOf, teams.keyById),
      calculationMetadata: await _metadata(
        contestId,
        current.asOfRound,
        scoreFields,
      ),
      publishedAt: _clock(),
      publishedBy: publishedBy,
      clientMutationId: clientMutationId,
    );
    return PublicationBuild(
      projection: projection,
      participants: [
        for (final p in pilots)
          if (p.changed != null) p.changed!,
      ],
    );
  }

  Map<String, Object?> _identity(
    Contest contest,
    String disciplineName,
    DateTime? lastActivityAt,
  ) => {
    'name': contest.name,
    'start': formatUtcTimestamp(contest.startDateTime),
    'end': formatUtcTimestamp(contest.endDateTime),
    'timezone': contest.timezone,
    'host': contest.host,
    'city': contest.city,
    'state': contest.state,
    'country': contest.country,
    'discipline': disciplineName,
    // What the status is worked out from when the contest is read (#454):
    // the lifecycle state and the last activity at publish time. The status
    // itself is never stored.
    'lifecycle_state': switch (contest.lifecycleState) {
      LifecycleState.created => 'Created',
      LifecycleState.configuring => 'Configuring',
      LifecycleState.ready => 'Ready',
      LifecycleState.running => 'Running',
      LifecycleState.completed => 'Completed',
    },
    'last_activity_at': lastActivityAt == null
        ? null
        : formatUtcTimestamp(lastActivityAt),
  };

  /// The pilots of the contest with their keys. A non-flying role is not
  /// published.
  Future<List<_Pilot>> _pilots(Id contestId, Id publicationId) async {
    final existing = {
      for (final row
          in await repository.publicationParticipantRepository
              .listForPublication(publicationId))
        if (row.sourceParticipationId != null) row.sourceParticipationId!: row,
    };
    final now = _clock();
    final pilots = <_Pilot>[];
    final participations = [
      ...await repository.contestParticipationRepository.listForContest(
        contestId,
      ),
    ]..sort((a, b) => a.id.value.compareTo(b.id.value));
    for (final participation in participations) {
      if (participation.roleType != RoleType.pilot) continue;
      final profile = await repository.participantProfileRepository.findById(
        participation.participantProfileId,
      );
      if (profile == null) continue;
      final row = existing[participation.id];
      final details = _details(profile);
      PublicationParticipant? changed;
      String key;
      if (row == null) {
        key = _newPilotKey();
        changed = PublicationParticipant(
          id: _newId(),
          publicationId: publicationId,
          pilotKey: key,
          sourceParticipationId: participation.id,
          details: details,
          createdAt: now,
          updatedAt: now,
        );
      } else {
        key = row.pilotKey;
        if (!row.isRedacted && _differs(row.details, details)) {
          changed = PublicationParticipant(
            id: row.id,
            publicationId: row.publicationId,
            pilotKey: row.pilotKey,
            sourceParticipationId: row.sourceParticipationId,
            details: details,
            publicProfileId: row.publicProfileId,
            createdAt: row.createdAt,
            updatedAt: now,
          );
        }
      }
      pilots.add(_Pilot(participation, key, changed));
    }
    return pilots;
  }

  bool _differs(Map<String, Object?>? a, Map<String, Object?> b) =>
      a == null ||
      a.length != b.length ||
      b.entries.any((e) => a[e.key] != e.value);

  /// The identifying details the results show. Email, FAI and national
  /// organisation numbers stay private.
  Map<String, Object?> _details(ParticipantProfile profile) => {
    'first_name': profile.firstName,
    'last_name': profile.lastName,
    'club': profile.club,
    'city': profile.city,
    'state': profile.state,
    'country': profile.country,
  };

  Future<_Teams> _teams(Id contestId, Map<Id, String> keyOf) async {
    final memberships = await repository.teamMembershipRepository
        .listForContest(contestId);
    final keyById = <Id, String>{};
    final keyByPilot = <String, String>{};
    final entries = <Object?>[];
    final teams = [...await repository.teamRepository.listForContest(contestId)]
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    for (final team in teams) {
      final members = [
        for (final m in memberships)
          if (m.teamId == team.id && keyOf[m.contestParticipationId] != null)
            keyOf[m.contestParticipationId]!,
      ]..sort();
      keyById[team.id] = team.id.value;
      for (final member in members) {
        keyByPilot[member] = team.id.value;
      }
      entries.add({
        'team_key': team.id.value,
        'name': team.name,
        'pilots': members,
      });
    }
    return _Teams(entries, keyById, keyByPilot);
  }

  Future<Map<String, Object?>> _matrixInfo(
    MatrixRevision matrix,
    List<Round> rounds,
    Map<Id, String> keyOf,
  ) async => {
    'rounds': [
      for (final round in rounds)
        {
          'round': round.ordinal,
          'group_count': round.groupCount,
          'assignments': [
            for (final a
                in await repository.matrixAssignmentRepository.listLiveForRound(
                  round.id,
                ))
              if (keyOf[a.contestParticipationId] != null)
                {
                  'pilot_key': keyOf[a.contestParticipationId],
                  'group': a.group,
                  'lane': a.lane,
                },
          ],
        },
    ],
  };

  /// The score fields whose raw values are published: what the scorer enters
  /// or flags, as figures the site can label. A landing is an id into the
  /// landing table (its points are already in the entry), a derived field is
  /// not a raw input, and free text could carry anything.
  List<DisciplineScoreField> _publicScoreFields(
    Iterable<DisciplineScoreField> fields,
  ) => [
    for (final field in fields)
      if (field.fieldKind != ScoreFieldKind.derived &&
          field.fieldType != ScoreFieldType.landing &&
          field.fieldType != ScoreFieldType.string)
        field,
  ];

  /// Each entry carries `raw_components`: the official score's values for the
  /// [fields], by field key, so the site can show flight time and the other
  /// raw inputs. A field the scorer left out is absent.
  Future<List<Object?>> _scores(
    Id contestId,
    List<Round> rounds,
    Map<Id, String> keyOf,
    List<DisciplineScoreField> fields,
  ) async {
    final official = <Id, Map<String, Object?>>{};
    final entries = <Object?>[];
    for (final round in rounds) {
      for (final flight in (await _results.round(
        contestId,
        round.ordinal,
      )).flights) {
        if (keyOf[flight.participationId] == null) continue;
        final placeholderId = flight.result.scorePlaceholderId;
        final components = official[placeholderId] ??=
            (await repository.officialScoreRepository.currentForPlaceholder(
              placeholderId,
            ))?.components ??
            const {};
        entries.add({
          'round': round.ordinal,
          'group': flight.group,
          'pilot_key': keyOf[flight.participationId],
          'outcome': flight.result.outcome.name,
          'raw_points': flight.result.rawPoints,
          'landing_points': flight.result.landingPoints,
          'penalty_points': flight.result.flightPenaltyPoints,
          'group_score': flight.result.groupScore,
          'selected': flight.result.isSelected,
          'preliminary': flight.result.isPreliminary,
          'raw_components': {
            for (final field in fields)
              if (components[field.fieldKey] != null)
                field.fieldKey: components[field.fieldKey],
          },
        });
      }
    }
    return entries;
  }

  Future<Map<String, Object?>> _standings(
    Id contestId,
    Map<Id, String> keyOf,
    Map<Id, String> teamKey,
  ) async {
    final pilotRows = await repository.participationStandingRepository
        .listForContest(contestId);
    final teamRows = await repository.teamStandingRepository.listForContest(
      contestId,
    );
    final rounds = {
      ...pilotRows.map((s) => s.asOfRound),
      ...teamRows.map((s) => s.asOfRound),
    }.toList()..sort();
    return {
      'rounds': [
        for (final round in rounds)
          {
            'as_of_round': round,
            'pilots': [
              for (final s in pilotRows.where((s) => s.asOfRound == round))
                if (keyOf[s.contestParticipationId] != null)
                  _pilotStanding(s, keyOf[s.contestParticipationId]!),
            ]..sort(_byPlace),
            'teams': [
              for (final s in teamRows.where((s) => s.asOfRound == round))
                if (teamKey[s.teamId] != null)
                  _teamStanding(s, teamKey[s.teamId]!, keyOf),
            ]..sort(_byPlace),
          },
      ],
    };
  }

  static int _byPlace(Map<String, Object?> a, Map<String, Object?> b) =>
      (a['place']! as int).compareTo(b['place']! as int);

  Map<String, Object?> _pilotStanding(ParticipationStanding s, String key) => {
    'pilot_key': key,
    'place': s.place,
    'tied': s.isTied,
    'raw_total': s.rawTotal,
    'dropped_rounds': s.droppedRounds,
    'penalty_total': s.penaltyTotal,
    'overall_score': s.overallScore,
    'preliminary': s.isPreliminary,
  };

  Map<String, Object?> _teamStanding(
    TeamStanding s,
    String key,
    Map<Id, String> keyOf,
  ) => {
    'team_key': key,
    'place': s.place,
    'tied': s.isTied,
    'team_score': s.teamScore,
    'counted_pilots': [
      for (final id in s.countedParticipations)
        if (keyOf[id] != null) keyOf[id],
    ],
    'preliminary': s.isPreliminary,
  };

  Future<String> _calculationVersion(Id contestId) async {
    final standings = await repository.participationStandingRepository
        .listForContest(contestId);
    if (standings.isNotEmpty) return standings.first.calculationVersion;
    final flights = await repository.flightResultRepository.listForContest(
      contestId,
    );
    return flights.isNotEmpty ? flights.first.calculationVersion : 'none';
  }

  Future<Map<String, Object?>> _metadata(
    Id contestId,
    int? asOfRound,
    List<DisciplineScoreField> scoreFields,
  ) async {
    final standings = await repository.participationStandingRepository
        .listForContest(contestId);
    final computedAt = standings.isEmpty
        ? null
        : standings
              .map((s) => s.computedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    return {
      'as_of_round': asOfRound,
      'computed_at': computedAt == null ? null : formatUtcTimestamp(computedAt),
      'score_fields': [
        for (final field in scoreFields)
          {
            'key': field.fieldKey,
            'name': field.name,
            'type': field.toJson()['field_type'],
            'unit': field.unit,
            'precision': field.precision,
          },
      ],
    };
  }

  Future<MatrixRevision?> _currentMatrix(Id contestId) async {
    final finalized = (await repository.matrixRevisionRepository.listForContest(
      contestId,
    )).where((r) => r.isFinalized).toList();
    return finalized.isEmpty ? null : finalized.last;
  }

  static String _randomKey() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 12; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}

class _Pilot {
  _Pilot(this.participation, this.key, this.changed);

  final ContestParticipation participation;
  final String key;

  /// The row to save, or null when the stored row is already current.
  final PublicationParticipant? changed;

  Map<String, Object?> entry(String? teamKey) => {
    'pilot_key': key,
    'classification': participation.classification,
    'number': participation.participantNumber,
    'retired_at_round': participation.retiredAtRound,
    'team_key': teamKey,
  };
}

class _Teams {
  _Teams(this.entries, this.keyById, this.keyByPilot);

  final List<Object?> entries;
  final Map<Id, String> keyById;
  final Map<String, String> keyByPilot;
}
