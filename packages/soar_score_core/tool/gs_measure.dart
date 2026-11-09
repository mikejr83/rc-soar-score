// Times the stages of reading a large GliderScore file: decoding the helper's
// output, the API round trip, and the mappers. Usage:
//   dart run tool/gs_measure.dart <snapshot.json> <copies>
// A snapshot is the gs-import/v1 JSON; its competitions are copied <copies>
// times (competition numbers offset) to make a large file.
import 'dart:convert';
import 'dart:io' as io;

import 'package:soar_score_core/soar_score_core.dart';

void main(List<String> args) {
  final json =
      jsonDecode(io.File(args[0]).readAsStringSync()) as Map<String, Object?>;
  final copies = int.parse(args[1]);
  final tables = (json['tables']! as List).cast<Map<String, Object?>>();
  const perComp = {'Comps', 'CompPilots', 'Scores', 'Dur'};
  final big = <Map<String, Object?>>[];
  for (final t in tables) {
    final rows = (t['rows']! as List).cast<Map<String, Object?>>();
    if (!perComp.contains(t['name'])) {
      big.add(t);
      continue;
    }
    final out = <Map<String, Object?>>[];
    for (var i = 0; i < copies; i++) {
      for (final r in rows) {
        final c = {...r};
        c['CompNo'] = (r['CompNo']! as num).toInt() + i * 1000;
        if (c['CompID'] != null) c['CompID'] = '${c['CompID']}-$i';
        out.add(c);
      }
    }
    big.add({...t, 'rows': out, 'rowCount': out.length});
  }
  final scores = big.firstWhere((t) => t['name'] == 'Scores')['rowCount'];
  io.stdout.writeln('Scores rows: $scores');

  // 1. what the helper's output costs to decode, one JSON object per line
  final lines = [
    for (final t in big)
      for (final r in (t['rows']! as List)) jsonEncode(r),
  ];
  var sw = Stopwatch()..start();
  for (final l in lines) {
    jsonDecode(l);
  }
  io.stdout.writeln(
    '1 decode ${lines.length} lines: ${sw.elapsedMilliseconds} ms',
  );

  // 2. the API round trip: encode on the server, decode on the client
  final payload = {'tables': big};
  sw = Stopwatch()..start();
  final text = jsonEncode(payload);
  final encodeMs = sw.elapsedMilliseconds;
  sw = Stopwatch()..start();
  final back = jsonDecode(text) as Map<String, Object?>;
  io.stdout.writeln(
    '2 encode ${text.length ~/ 1024} KB: $encodeMs ms, decode: '
    '${sw.elapsedMilliseconds} ms',
  );

  final result = GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: 'big.mdb',
    tables: [
      for (final t in (back['tables']! as List).cast<Map<String, Object?>>())
        GliderScoreTable(
          name: t['name']! as String,
          rows: (t['rows']! as List).cast<Map<String, Object?>>(),
          rowCount: t['rowCount']! as int,
          rowCapExceeded: false,
        ),
    ],
  );

  // 3. the mappers
  sw = Stopwatch()..start();
  final plans = const GliderScoreRestoreMapper().map(result);
  io.stdout.writeln(
    '3 restore mapper (${plans.length} competitions, '
    '${plans.fold<int>(0, (n, p) => n + p.flights.length)} flights): '
    '${sw.elapsedMilliseconds} ms',
  );
}
