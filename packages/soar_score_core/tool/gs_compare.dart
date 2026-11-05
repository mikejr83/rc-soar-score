// Recalculates every scored flight of GliderScore snapshots with Soar Score's
// calculator and compares it with GliderScore's RawScore, the same gate the
// import runs inside its transaction (ADR 0006, amendment 2).
//
// Usage: dart run tool/gs_compare.dart <snapshot.json | directory> ...
//
// A snapshot is the `gs-import/v1` JSON the import reads (the fixtures under
// test/fixtures/gliderscore are examples). Exit code 1 when a flight differs.
import 'dart:convert';
import 'dart:io' as io;

import 'package:soar_score_core/soar_score_core.dart';

GliderScoreImportResult _read(io.File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: json['sourceDbFile']! as String,
    tables: [
      for (final t
          in (json['tables']! as List<Object?>).cast<Map<String, Object?>>())
        GliderScoreTable(
          name: t['name']! as String,
          rows: (t['rows']! as List<Object?>).cast<Map<String, Object?>>(),
          rowCount: t['rowCount']! as int,
          rowCapExceeded: t['rowCapExceeded']! as bool,
        ),
    ],
  );
}

Map<String, double> _landingPoints(LandingSelection? landing) {
  if (landing == null) return const {};
  final table = switch (landing.systemTable) {
    'f5jDistance' => SystemLandingTables.f5jDistance,
    'f5jStandard' => SystemLandingTables.f5jStandard,
    _ => null,
  };
  return {
    if (table != null)
      for (final r in table.results) r.entryKey: r.pointValue.toDouble(),
    for (final e in landing.entries) e.entryKey: e.points.toDouble(),
  };
}

void main(List<String> args) {
  if (args.isEmpty) {
    io.stderr.writeln('usage: dart run tool/gs_compare.dart <file|dir> ...');
    io.exit(64);
  }
  final files = <io.File>[];
  for (final arg in args) {
    if (io.FileSystemEntity.isDirectorySync(arg)) {
      files.addAll(
        io.Directory(arg)
            .listSync()
            .whereType<io.File>()
            .where((f) => f.path.endsWith('.json')),
      );
    } else {
      files.add(io.File(arg));
    }
  }
  var failed = 0;
  for (final file in files) {
    final GliderScoreImportResult snapshot;
    try {
      snapshot = _read(file);
    } on Object {
      continue; // not a snapshot (an expected-value file, say)
    }
    for (final plan in const GliderScoreRestoreMapper().map(snapshot)) {
      if (!plan.isImportable) {
        io.stdout.writeln(
          '${file.path} comp ${plan.sourceCompNo}: not restorable '
          '(${plan.reason})',
        );
        continue;
      }
      final result = const GliderScoreRestoreComparison().check(
        plan.flights,
        overrides: plan.contest.config?.discipline ?? const {},
        landingPoints: _landingPoints(plan.landing),
      );
      io.stdout.writeln(
        '${file.path} comp ${plan.sourceCompNo}: ${result.checked} flights, '
        '${result.mismatchCount} differ',
      );
      for (final m in result.mismatches) {
        io.stdout.writeln(
          '  round ${m.roundNo} group ${m.groupNo} pilot ${m.sourcePilotNo}'
          '${m.reflightNo > 0 ? ' re-flight ${m.reflightNo}' : ''}: '
          'GliderScore ${m.expected}, Soar Score ${m.actual ?? m.error}',
        );
      }
      if (!result.passed) failed++;
    }
  }
  io.exit(failed == 0 ? 0 : 1);
}
