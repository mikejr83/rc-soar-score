import 'package:soar_score_core/soar_score_core.dart';

import '../report_pilot.dart';
import 'score_export_error.dart';
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
    required this.rounds,
    required this.standings,
    required this.flights,
  });

  /// Builds the source from one [reportData] read and the shown rounds in
  /// [options].
  ///
  /// The read must carry the facts, the scores and the standings of the shown
  /// rounds: `reportData(facts: true, scores: true, asOfRound: options.to,
  /// rounds: options.rounds)`. Without the facts the pilot names and teams are
  /// blank; without the scores the time and height are blank; and the standings
  /// are required and must be as of `options.to`. A violation throws a
  /// [ScoreExportError].
  factory ScoreExportSource.of(ReportData data, ScoreExportOptions options) {
    final rangeError = options.check();
    if (rangeError != null) {
      throw ScoreExportError(rangeError);
    }
    // The export needs the whole read: the facts (names, numbers, teams,
    // classes), the scores (time, height), and the standings. A read made
    // with facts: false or scores: false would silently blank the file, so a
    // missing part is refused rather than exported.
    final results = data.results;
    if (results == null || results.standings.isEmpty) {
      throw ScoreExportError(
        'No standings are stored yet. Save a score on the Scoring page and '
        'try again.',
      );
    }
    if (results.asOfRound != options.to) {
      throw ScoreExportError(
        'The standings are as of round ${results.asOfRound}, but the export '
        'shows rounds to ${options.to}.',
      );
    }
    final rounds = options.rounds;
    final roundResults = data.roundResults;
    if (roundResults == null ||
        rounds.any(
          (round) =>
              roundResults.indexWhere((r) => r.ordinal == round).isNegative,
        )) {
      throw ScoreExportError(
        'The report read did not include the flights of the rounds shown '
        '(rounds ${rounds.join(', ')}).',
      );
    }
    if (data.participations == null ||
        data.participants == null ||
        data.scores == null) {
      throw ScoreExportError(
        'The report read is incomplete: it does not include the pilots and '
        'scores the export needs. Read the contest with facts and scores '
        'included.',
      );
    }
    final pilots = _pilots(data);
    final standingOf = {
      for (final standing in results.standings)
        standing.contestParticipationId: standing,
    };
    final componentsOf = _officialComponents(data);
    final byRound = {for (final round in roundResults) round.ordinal: round};

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
    final ordered = [
      for (final standing in results.standings)
        if (pilots.containsKey(standing.contestParticipationId)) standing,
    ];
    if (ordered.isEmpty) {
      // The standings are stored, but none of them matches a pilot of this
      // read: exporting would produce a header-only file.
      throw ScoreExportError(
        'No standing matches the pilots of this read. The read may be '
        'inconsistent; try again.',
      );
    }
    final standings = <ExportStandingsRow>[];
    final top = ordered.first.overallScore;
    for (final standing in ordered) {
      final pilot = pilots[standing.contestParticipationId]!;
      final cells = <int, ExportStandingsCell>{};
      for (final round in rounds) {
        final retired =
            pilot.retiredAtRound != null && round >= pilot.retiredAtRound!;
        // A round after retirement is a plain zero without a flight behind it.
        cells[round] = ExportStandingsCell(
          score:
              selectedOf[round]?[pilot.participationId] ??
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
          penalty: _signed(standing.penaltyTotal),
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
      final ordered =
          [
            for (final flight in result.flights)
              if (pilots.containsKey(flight.participationId)) flight,
          ]..sort((a, b) {
            if (a.group != b.group) return a.group.compareTo(b.group);
            final byScore = b.result.groupScore.compareTo(a.result.groupScore);
            if (byScore != 0) return byScore;
            // A tiebreak keeps the order deterministic (List.sort is not
            // stable) and reads sensibly: by name, then id.
            final byName = pilots[a.participationId]!.listName.compareTo(
              pilots[b.participationId]!.listName,
            );
            if (byName != 0) return byName;
            return a.participationId.value.compareTo(b.participationId.value);
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
      contestName: data.contest.name,
      decimalPlaces: _decimalPlaces(data),
      rounds: rounds,
      standings: standings,
      flights: flights,
    );
  }

  /// The contest's name, for the file name and the report column.
  final String contestName;

  /// How many decimals a score shows.
  final int decimalPlaces;

  /// The rounds the export shows, ascending.
  final List<int> rounds;

  /// The standings view: one row per pilot, in rank order.
  final List<ExportStandingsRow> standings;

  /// The flight view: one row per flight, by round then group then score.
  final List<ExportFlightRow> flights;

  static Map<Id, ReportPilot> _pilots(ReportData data) {
    final profiles = {
      for (final p in data.participants ?? const <ParticipantProfile>[])
        p.id: p,
    };
    final teams = {for (final t in data.teams ?? const <Team>[]) t.id: t.name};
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
  static Map<Id, Map<String, Object?>> _officialComponents(ReportData data) => {
    for (final slot in data.scores?.slots ?? const <ScoreSlot>[])
      if (slot.officialScore != null)
        slot.placeholder.id: slot.officialScore!.components,
  };

  static int _decimalPlaces(ReportData data) {
    final configuration = data.configuration;
    if (configuration == null) return 1;
    try {
      return configuration.config.coreOptions.decimalPlaces;
    } on ArgumentError {
      // A configuration that fails to read has no usable decimals.
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

  /// A value that formats as "-0.0" through toStringAsFixed is shown as 0.0.
  static double _signed(double value) =>
      value == 0 || value.toStringAsFixed(3) == '-0.000' ? 0.0 : value;
}
