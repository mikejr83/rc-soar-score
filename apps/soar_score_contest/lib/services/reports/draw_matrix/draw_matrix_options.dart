import 'dart:math' as math;

import '../reports_facts.dart';
import '../viewer/report_spec.dart';

/// The filters and options of the Draw Matrix, read from the viewer's filter
/// map (and so from the URL) with the contest's facts.
///
/// Filter keys: `from` and `to` (an inclusive round range, all drawn rounds
/// when absent), `cmp` (compact mode), `inf` (additional pilot info) and, for
/// that, `club`, `fai` and `nat`. A key the URL leaves out takes its default.
class DrawMatrixOptions {
  DrawMatrixOptions._({
    required this.from,
    required this.requestedTo,
    required this.to,
    required this.drawn,
    required this.planned,
    required this.rounds,
    required this.compact,
    required this.additionalChosen,
    required this.club,
    required this.fai,
    required this.national,
  });

  factory DrawMatrixOptions.of(
    Map<String, String> filters,
    ReportsFacts facts,
  ) => DrawMatrixOptions.parse(
    filters,
    drawnRounds: facts.roundOrdinals,
    intendedTotalRounds: facts.intendedTotalRounds,
  );

  /// Reads [filters] for a contest whose drawn rounds are [drawnRounds]
  /// (ascending) and that plans [intendedTotalRounds] in all, if it says.
  factory DrawMatrixOptions.parse(
    Map<String, String> filters, {
    required List<int> drawnRounds,
    int? intendedTotalRounds,
  }) {
    bool on(String key, bool fallback) =>
        filters[key] == null ? fallback : filters[key] == '1';
    final ordinals = drawnRounds;
    final lastDrawn = ordinals.isEmpty ? 0 : ordinals.last;
    final from = int.tryParse(filters['from'] ?? '') ?? 1;
    final requestedTo = int.tryParse(filters['to'] ?? '') ?? lastDrawn;
    final to = math.min(requestedTo, lastDrawn);
    return DrawMatrixOptions._(
      from: from,
      requestedTo: requestedTo,
      to: to,
      drawn: lastDrawn,
      planned: math.max(intendedTotalRounds ?? 0, lastDrawn),
      rounds: [
        for (final round in ordinals)
          if (round >= from && round <= to) round,
      ],
      compact: on('cmp', false),
      additionalChosen: on('inf', false),
      club: on('club', true),
      fai: on('fai', true),
      national: on('nat', false),
    );
  }

  /// The filters that apply when the URL names none.
  static Map<String, String> defaults(ReportsFacts facts) => const {
    'from': '1',
  };

  /// The first round shown.
  final int from;

  /// The upper bound the director chose, which may name an undrawn round.
  final int requestedTo;

  /// The last round shown: [requestedTo] held to the last drawn round.
  final int to;

  /// The last drawn round.
  final int drawn;

  /// The rounds the contest plans to fly: the drawn ones, or more while a
  /// seeded contest draws a round at a time.
  final int planned;

  /// The drawn rounds shown, ascending.
  final List<int> rounds;

  /// Two small-type columns per page.
  final bool compact;

  /// The director's choice, kept while compact mode makes it unavailable.
  final bool additionalChosen;
  final bool club;
  final bool fai;
  final bool national;

  /// Additional pilot info is not available in compact mode.
  bool get additionalAvailable => !compact;

  /// Club, FAI ID and National ID columns are on: asked for and not compact.
  bool get additional => additionalChosen && !compact;

  bool get showClub => additional && club;
  bool get showFai => additional && fai;
  bool get showNational => additional && national;

  /// Every drawn round is shown.
  bool get isAll => from <= 1 && requestedTo >= drawn;

  /// Rounds planned but not drawn yet.
  bool get hasUndrawn => planned > drawn;

  /// Judges the range: invalid when the lower bound is above the upper one,
  /// empty when no drawn round is in it.
  ReportCheck check() {
    if (from > requestedTo) {
      return const ReportInvalid(
        'From round must be on or before To round. The sheet still shows the '
        'last rounds that were valid.',
      );
    }
    if (rounds.isEmpty) {
      final single = from == requestedTo;
      final range = single ? 'Round $from' : 'Rounds $from–$requestedTo';
      return ReportEmpty(
        title: 'No drawn rounds in this range',
        body: drawn == 0
            ? '$range isn’t drawn. No round has been drawn yet.'
            : '$range ${single ? 'isn’t' : 'aren’t'} drawn. Only '
                  '${drawn == 1 ? 'round 1' : 'rounds 1 to $drawn'} can be '
                  'printed.',
      );
    }
    return ReportCheck.ok;
  }

  /// The line under the range controls.
  String get rangeMessage {
    final rest = !hasUndrawn
        ? ''
        : drawn + 1 == planned
        ? ' Round $planned isn’t drawn yet.'
        : ' Rounds ${drawn + 1} to $planned aren’t drawn yet.';
    if (isAll) {
      return '${hasUndrawn ? 'All drawn rounds.' : 'All rounds.'}$rest';
    }
    return 'Showing rounds $from to $to of $drawn.$rest';
  }

  /// The filters in a few words: "Rounds 1–6 · Compact".
  String get summary {
    final range = isAll
        ? 'All rounds'
        : from == to
        ? 'Round $from'
        : 'Rounds $from–$to';
    return '$range${compact ? ' · Compact' : ''}';
  }
}
