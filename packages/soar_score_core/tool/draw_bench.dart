// Benchmark harness for the matrix draw engine.
//
//   dart run tool/draw_bench.dart [--layout c1|c4|c10|all] [--seeds N] [--check]
//
// Runs the research layouts of `research/gliderscore-draw/draw_bench.py`
// (team numbers only, no pilot data) through [DrawEngine] and prints the mean
// absolute deviation (MAD) of the meeting counts, the never-met pairs, the
// maximum repeat and the variance, as the median over the seeds. With
// `--check` it compares each layout with its stored baseline and exits 1 on a
// regression. It lives in `tool/` so the default `dart test` run skips it.
import 'dart:io';

import 'package:soar_score_core/soar_score_core.dart';

/// One research layout: [teams] holds the team number of every pilot, with 0
/// for none.
class _Layout {
  const _Layout({
    required this.name,
    required this.groups,
    required this.rounds,
    required this.teamProtection,
    required this.teams,
    required this.baseline,
  });

  final String name;
  final int groups;
  final int rounds;
  final bool teamProtection;
  final List<int> teams;
  final _Baseline baseline;
}

/// What a layout must keep reaching, in the quality order: never-met pairs,
/// then maximum repeat, then variance. [mad] is the stored reference figure;
/// the check allows [madTolerance] above it.
class _Baseline {
  const _Baseline({
    required this.unmet,
    required this.maxRepeat,
    required this.variance,
    required this.mad,
  });

  final int unmet;
  final int maxRepeat;
  final double variance;
  final double mad;

  static const double madTolerance = 0.10;
}

const _layouts = [
  _Layout(
    name: 'c1',
    groups: 5,
    rounds: 16,
    teamProtection: true,
    teams: [
      8,
      8,
      6,
      4,
      3,
      8,
      5,
      5,
      4,
      3,
      3,
      3,
      1,
      1,
      2,
      6,
      1,
      6,
      2,
      7,
      4,
      7,
      4,
      2,
      7,
      8,
      5,
      5,
      1,
      7,
    ],
    baseline: _Baseline(unmet: 0, maxRepeat: 5, variance: 0.40, mad: 0.42),
  ),
  _Layout(
    name: 'c4',
    groups: 5,
    rounds: 14,
    teamProtection: true,
    teams: [
      1,
      1,
      10,
      6,
      9,
      3,
      3,
      3,
      4,
      8,
      13,
      9,
      9,
      11,
      11,
      11,
      9,
      6,
      6,
      6,
      13,
      13,
      5,
      12,
      10,
      10, //
      10,
      10,
      14,
      14,
      8,
      8,
      13,
      5,
      14,
      2,
      2,
      2,
      14,
      11,
      14,
      8,
      7,
      1,
      4,
      8,
      7,
      7,
      9,
      11,
      5,
      3, //
      4, 4, 13, 12, 2, 2, 12, 12, 7, 5, 12,
    ],
    baseline: _Baseline(unmet: 0, maxRepeat: 5, variance: 0.76, mad: 0.70),
  ),
  _Layout(
    name: 'c10',
    groups: 3,
    rounds: 6,
    teamProtection: false,
    teams: [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ],
    baseline: _Baseline(unmet: 0, maxRepeat: 4, variance: 0.76, mad: 0.71),
  ),
];

class _Row {
  _Row(this.mad, this.unmet, this.maxRepeat, this.variance, this.seconds);

  final double mad;
  final int unmet;
  final int maxRepeat;
  final double variance;
  final double seconds;
}

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

_Row _run(_Layout layout, int seed) {
  final pilots = [
    for (var i = 0; i < layout.teams.length; i++)
      DrawPilot(
        _id(i + 1),
        teamId: layout.teams[i] == 0 ? null : _id(1000 + layout.teams[i]),
      ),
  ];
  final watch = Stopwatch()..start();
  final result = const DrawEngine().generate(
    pilots: pilots,
    rounds: layout.rounds,
    groupsPerRound: layout.groups,
    teamProtection: layout.teamProtection,
    laneMode: LaneMode.none,
    seed: seed,
  );
  watch.stop();
  final stats = MatchupStats.of(
    result.rounds,
    teamProtection: layout.teamProtection,
  );
  var squares = 0.0;
  for (final entry in stats.histogram.entries) {
    squares +=
        entry.value * (entry.key - stats.mean) * (entry.key - stats.mean);
  }
  return _Row(
    stats.meanAbsoluteDeviation,
    stats.unmet,
    stats.maxDuplicates,
    squares / stats.feasiblePairs,
    watch.elapsedMilliseconds / 1000,
  );
}

T _median<T extends Comparable<Object>>(List<_Row> rows, T Function(_Row) key) {
  final values = rows.map(key).toList()..sort();
  return values[values.length ~/ 2];
}

/// The baselines are medians over this many seeds (seeds 1 to N).
const _baselineSeeds = 5;

Never usage([String? problem]) {
  if (problem != null) stderr.writeln(problem);
  stderr.writeln(
    'usage: dart run tool/draw_bench.dart [--layout c1|c4|c10|all] [--seeds N] [--check]',
  );
  exit(64);
}

void main(List<String> args) {
  var which = 'all';
  var seeds = _baselineSeeds;
  var check = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--layout':
        if (i + 1 >= args.length) usage();
        which = args[++i];
      case '--seeds':
        final value = i + 1 < args.length ? int.tryParse(args[++i]) : null;
        if (value == null || value < 1) usage();
        seeds = value;
      case '--check':
        check = true;
      default:
        usage();
    }
  }
  if (check && seeds != _baselineSeeds) {
    usage(
      '--check compares against baselines taken with $_baselineSeeds seeds',
    );
  }
  final chosen = _layouts
      .where((l) => which == 'all' || l.name == which)
      .toList();
  if (chosen.isEmpty) {
    usage('unknown layout "$which"');
  }

  final failures = <String>[];
  for (final layout in chosen) {
    final rows = [for (var s = 1; s <= seeds; s++) _run(layout, s)];
    final mad = _median(rows, (r) => r.mad);
    final unmet = _median(rows, (r) => r.unmet);
    final maxRepeat = _median(rows, (r) => r.maxRepeat);
    final variance = _median(rows, (r) => r.variance);
    final seconds = _median(rows, (r) => r.seconds);
    stdout.writeln(
      '${layout.name}: pilots=${layout.teams.length} groups=${layout.groups} '
      'rounds=${layout.rounds} MAD=${mad.toStringAsFixed(4)} '
      'neverMet=$unmet maxRepeat=$maxRepeat '
      'variance=${variance.toStringAsFixed(4)} time=${seconds.toStringAsFixed(2)}s',
    );
    stdout.writeln(
      '    MAD per seed=${[for (final r in rows) r.mad.toStringAsFixed(4)]}',
    );
    if (!check) continue;
    final b = layout.baseline;
    // Quality order: never-met pairs, then maximum repeat, then variance.
    if (unmet > b.unmet) {
      failures.add('${layout.name}: never-met pairs $unmet > ${b.unmet}');
    } else if (maxRepeat > b.maxRepeat) {
      failures.add('${layout.name}: max repeat $maxRepeat > ${b.maxRepeat}');
    } else if (variance > b.variance) {
      failures.add('${layout.name}: variance $variance > ${b.variance}');
    }
    if (mad > b.mad * (1 + _Baseline.madTolerance)) {
      failures.add('${layout.name}: MAD $mad > ${b.mad} + tolerance');
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln('Benchmark regressions:');
    failures.forEach(stderr.writeln);
    exit(1);
  }
  if (check) stdout.writeln('All layouts meet their baselines.');
}
