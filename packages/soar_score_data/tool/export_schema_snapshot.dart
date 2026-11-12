import 'dart:io';

import 'package:soar_score_data/schema/custom_indexes.dart';
import 'package:soar_score_data/soar_score_data.dart';

/// Freezes the current Drift-generated table DDL and custom indexes.
Future<void> main() async {
  final db = createInMemoryDatabase();
  final version = db.schemaVersion;
  await db.close();
  final directory = Directory('schema_snapshots');
  await directory.create(recursive: true);
  final outputs = <File, String>{};
  for (final dialect in ['sqlite', 'postgres']) {
    final file = File('${directory.path}/v${version}_$dialect.sql');
    if (await file.exists()) {
      throw StateError(
        '${file.path} already exists; published snapshots are immutable.',
      );
    }
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'drift_dev',
      'schema',
      'export',
      '--dialect',
      dialect,
      'lib/database.dart',
    ]);
    if (result.exitCode != 0) {
      throw StateError('Schema export failed for $dialect: ${result.stderr}');
    }
    final tables = (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('CREATE TABLE '))
        .toList();
    if (tables.isEmpty) throw StateError('No tables exported for $dialect.');
    final indexes = [
      for (final entries in customIndexes.values)
        for (final sql in entries) '$sql;',
    ];
    outputs[file] = [...tables, ...indexes].join('\n') + '\n';
  }
  for (final entry in outputs.entries) {
    await entry.key.writeAsString(entry.value);
    stdout.writeln('Wrote ${entry.key.path}');
  }
}
