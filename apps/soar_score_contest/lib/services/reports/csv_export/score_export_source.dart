import 'package:soar_score_core/soar_score_core.dart';

import '../report_pilot.dart';
import 'score_export_options.dart';

/// One pilot's score in one of the shown rounds, for the standings view.
class ExportStandingsCell {
  const ExportStandingsCell({this.score, this.dropped = false});

  /// The round score; `null` when the pilot has no score in the round.
  final double? score;

  /// The round was dropped from the total.
  final bool dropped;
}

/// One pilot's row of the standings view, in rank order.
class ExportStandingsRow {
  const ExportStandingsRow({
    required this.place,
    required this.pilot,
    required this.total,
    required this.raw,
    required this.penalty,
    required this.percentage,
    required this.cells,
  });

  final int place;
  final ReportPilot pilot;

  /// Kept round scores less the penalty.
  final double total;

  /// The total plus the dropped rounds: every round score, less the penalty.
  final double raw;

  /// The penalty deducted from the total; 0 for none.
  final double penalty;

  /// The total as a percentage of the winner's; `null` when the winner has
  /// nothing to compare with.
  final double? percentage;

  /// The shown rounds, by ordinal.
  final Map<int, ExportStandingsCell> cells;
}

/// One flight of the shown rounds, for the flight view. Every flight is
/// included; [selected] marks the one that counts for the pilot's round.
class ExportFlightRow {
  const ExportFlightRow({
    required this.pilot,
    required this.round,
    required this.group,
    required this.roundScore,
    required this.raw,
    required this.selected,
    this.seconds,
    this.height,
    this.landing,
    this.flightPenalty,
    this.cumulativePenalty,
    this.place,
    this.total,
  });

  final ReportPilot pilot;

  /// The round ordinal the flight flew in.
  final int round;

  /// The group as a letter ("A").
  final String group;

  /// The recorded flight time in seconds; `null` when not recorded.
  final int? seconds;

  /// The launch height in metres; `null` when not recorded (F5J only).
  final int? height;

  /// The landing points; `null` when none were awarded.
  final double? landing;

  /// The flight's raw points (flight points plus landing less penalties).
  final double? raw;

  /// The penalty on this flight; `null` when none.
  final double? flightPenalty;

  /// The cumulative penalty applied to the pilot's total; `null` when none.
  final double? cumulativePenalty;

  /// The score the flight achieved in its round (`groupScore`).
  final double roundScore;

  /// Whether this flight supplies the pilot's round result for its round.
  final bool selected;

  /// The pilot's overall place, repeated so a pivot on Pilot reproduces the
  /// standings. `null` before any standing is stored.
  final int? place;

  /// The pilot's overall total, repeated as above.
  final double? total;
}

/// The normalized input to a CSV export, built fresh from one [ReportData]
/// read and the shown round range in [options]. It carries both views a format
/// can render: one row per pilot (standings) and one row per flight.
class ScoreExportSource {
  const ScoreExportSource({
    required this.contestName,
    required this.decimalPlaces,
    required this.discipline,
    required this.rounds,
    required this.standings,
    required this.flights,
  });

  /// Builds the source from one [reportData] read and the shown rounds in
  /// [options]. The discipline is resolved from the saved configuration
  /// against the system profiles, the same way the workspace does.
  factory ScoreExportSource.of(ReportData reportData, ScoreExportOptions options) {
    final rounds = options.rounds;
    final pilots = _pilots(reportData);
    final standingOf = {
      for (final standing in reportData.results?.standings ?? const <ParticipationStanding>[])
        standing.contestParticipationId: standing,
    };
    final componentsOf = _officialComponents(reportData);
    final byRound = {
      for (final round in reportData.roundResults ?? const <RoundResults>[])
        round.ordinal: round,
    };

    // The selected flight of each shown round, by pilot, so the standings view
    // can read a round score without a per-round lookup.
    final selectedOf = <int, Map<Id, double>>{};
    for (final round in rounds) {
      final result = byRound[round];
      if (result == null) continue;
      final byPilot = <Id, double>{};
      for (final flight in result.flights) {
        if (flight.result.isSelected) {
          byPilot[flight.participationId] = flight.result.groupScore;
        }
      }
      selectedOf[round] = byPilot;
    }

    // Standings view: one row per pilot, in the stored rank order, with a cell
    // per shown round.
    final standings = <ExportStandingsRow>[];
    final ordered = [
      for (final standing in reportData.results?.standings ?? const <ParticipationStanding>[])
        if (pilots.containsKey(standing.contestParticipationId)) standing,
    ];
    final top = ordered.isEmpty ? 0.0 : ordered.first.overallScore;
    for (final standing in ordered) {
      final pilot = pilots[standing.contestParticipationId];
      if (pilot == null) continue;
      final cells = <int, ExportStandingsCell>{};
      for (final round in rounds) {
        final retired =
            pilot.retiredAtRound != null && round >= pilot.retiredAtRound!;
        // A round after retirement is a plain zero without a flight behind it.
        cells[round] = ExportStandingsCell(
          score: selectedOf[round]?[pilot.participationId] ??
              (retired ? 0.0 : null),
          dropped: standing.droppedRounds.contains(round),
        );
      }
      standings.add(
        ExportStandingsRow(
          place: standing.place,
          pilot: pilot,
          total: standing.overallScore,
          raw: standing.rawTotal - standing.penaltyTotal,
          penalty: standing.penaltyTotal,
          percentage: top > 0 ? standing.overallScore / top * 100 : null,
          cells: cells,
        ),
      );
    }

    // Flight view: every flight of the shown rounds, not only the selected
    // one, ordered by round, then group, then score (best first).
    final flights = <ExportFlightRow>[];
    for (final round in rounds) {
      final result = byRound[round];
      if (result == null) continue;
      final ordered = [
        for (final flight in result.flights)
          if (pilots.containsKey(flight.participationId)) flight,
      ]..sort((a, b) {
        if (a.group != b.group) return a.group.compareTo(b.group);
        return b.result.groupScore.compareTo(a.result.groupScore);
      });
      for (final flight in ordered) {
        final pilot = pilots[flight.participationId]!;
        final standing = standingOf[flight.participationId];
        final components = componentsOf[flight.result.scorePlaceholderId];
        flights.add(
          ExportFlightRow(
            pilot: pilot,
            round: round,
            group: _groupLetter(flight.group - 1),
            seconds: _int(components?['time_flown']),
            height: _int(components?['launch_height']),
            landing: flight.result.landingPoints,
            raw: flight.result.rawPoints,
            flightPenalty: flight.result.flightPenaltyPoints,
            cumulativePenalty: flight.result.cumulativePenalty?.toDouble(),
            roundScore: flight.result.groupScore,
            selected: flight.result.isSelected,
            place: standing?.place,
            total: standing?.overallScore,
          ),
        );
      }
    }

    return ScoreExportSource(
      contestName: reportData.contest.name,
      decimalPlaces: _decimalPlaces(reportData),
      discipline: _disciplineType(reportData),
      rounds: rounds,
      standings: standings,
      flights: flights,
    );
  }

  /// The contest's name, for the file name and the report column.
  final String contestName;

  /// How many decimals a score shows.
  final int decimalPlaces;

  /// The discipline the contest scores, or `null` when the configuration is
  /// missing or not a system profile.
  final DisciplineType? discipline;

  /// The rounds the export shows, ascending.
  final List<int> rounds;

  /// The standings view: one row per pilot, in rank order.
  final List<ExportStandingsRow> standings;

  /// The flight view: one row per flight, by round then group then score.
  final List<ExportFlightRow> flights;

  /// The discipline records a launch height (F5J); F3J and the others do not.
  bool get hasLaunchHeight => discipline == DisciplineType.f5j;

  static Map<Id, ReportPilot> _pilots(ReportData data) {
    final profiles = {
      for (final p in data.participants ?? const <ParticipantProfile>[]) p.id: p,
    };
    final teams = {
      for (final t in data.teams ?? const <Team>[]) t.id: t.name,
    };
    final teamOf = {
      for (final m in data.teamMemberships ?? const <TeamMembership>[])
        m.contestParticipationId: m.teamId,
    };
    return {
      for (final p in data.participations ?? const <ContestParticipation>[])
        if (p.roleType == RoleType.pilot)
          p.id: ReportPilot(
            participationId: p.id,
            firstName: profiles[p.participantProfileId]?.firstName ?? '',
            lastName: profiles[p.participantProfileId]?.lastName ?? 'Unknown',
            number: p.participantNumber,
            team: teams[teamOf[p.id]],
            className: p.classification,
            retiredAtRound: p.retiredAtRound,
          ),
    };
  }

  /// The official score components, by placeholder id.
  static Map<Id, Map<String, Object?>> _officialComponents(ReportData data) =>
      {
        for (final slot in data.scores?.slots ?? const <ScoreSlot>[])
          if (slot.officialScore != null)
            slot.placeholder.id: slot.officialScore!.components,
      };

  static DisciplineType? _disciplineType(ReportData data) {
    final configuration = data.configuration;
    if (configuration == null) return null;
    for (final profile in SystemDisciplineProfiles.all) {
      if (profile.profile.id == configuration.disciplineProfileId) {
        return profile.profile.type;
      }
    }
    return null;
  }

  static int _decimalPlaces(ReportData data) {
    final configuration = data.configuration;
    if (configuration == null) return 1;
    try {
      return configuration.config.coreOptions.decimalPlaces;
    } on Object {
      return 1;
    }
  }

  static String _groupLetter(int index) {
    var n = index;
    var label = '';
    do {
      label = String.fromCharCode(0x41 + n % 26) + label;
      n = n ~/ 26;
    } while (n > 0);
    return label;
  }

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}
