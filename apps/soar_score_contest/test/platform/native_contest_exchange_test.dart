import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/platform/rolling_log_file.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
import 'package:soar_score_contest/services/exchange/support_bundle.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

/// A contest sent from one installation to another, through the exchange the
/// screens use.
void main() {
  late Directory dir;
  late EmbeddedServer source;
  late EmbeddedServer target;
  late NativeContestExchange from;
  late NativeContestExchange to;
  late core.Id contestId;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('native_contest_exchange');
    source = await startEmbeddedServer('${dir.path}/source.db');
    target = await startEmbeddedServer('${dir.path}/target.db');
    from = NativeContestExchange(source);
    to = NativeContestExchange(target);
    final client = ApiClient(
      baseUrl: source.baseUrl,
      tokenProvider: () async => source.secret,
    );
    contestId = core.Id.create();
    await client.createContest(
      CreateContestRequest(
        id: contestId,
        name: 'Sent: Spring/Fling?',
        startDateTime: DateTime.utc(2026, 5, 1),
        endDateTime: DateTime.utc(2026, 5, 2),
        timezone: 'America/Denver',
      ),
    );
    client.close();
  });

  tearDown(() async {
    await source.close();
    await target.close();
    dir.deleteSync(recursive: true);
  });

  test('the file is named after the contest, safely', () async {
    final export = await from.export(contestId, redact: true);

    expect(export.fileName, 'Sent SpringFling.rcsoar');
  });

  test(
    'an export for support is a container with the log, unredacted',
    () async {
      final logDir = Directory('${dir.path}/logs');
      final log = RollingLogFile(logDir)
        ..write('INFO Sync: pulled 3 mutations');
      final exchange = NativeContestExchange(
        source,
        log: log,
        installation: () async => {'installation_id': 'abc'},
      );
      addTearDown(log.close);

      final export = await exchange.export(
        contestId,
        redact: true,
        forSupport: true,
      );

      expect(export.fileName, 'Sent SpringFling.rcsoar');
      final archive = ZipDecoder().decodeBytes(export.bytes);
      String text(String name) =>
          utf8.decode(archive.findFile(name)!.readBytes()!);
      final manifest = jsonDecode(text('manifest.json')) as Map;
      expect(manifest['format'], 'rcsoar-support');
      expect(manifest['installation_id'], 'abc');
      expect(manifest['redacted'], isFalse);
      expect(manifest['log_files'], [
        {'name': 'soar-score.log', 'bytes': greaterThan(0)},
      ]);
      expect(text('app.log'), contains('pulled 3 mutations'));
      expect(
        (jsonDecode(text('contest.json')) as Map)['header'],
        containsPair('redacted', false),
      );
    },
  );

  test('an export for support imports like a plain one', () async {
    final exchange = NativeContestExchange(source, log: null);
    final bytes = (await exchange.export(
      contestId,
      redact: true,
      forSupport: true,
    )).bytes;

    final preview = await to.preview(bytes);
    expect(preview.contestName, 'Sent: Spring/Fling?');
    final imported = await to.import(bytes, ExchangeImportMode.inspection);
    expect(await to.inspectionContests(), {imported.contestId});
  });

  test('a plain export has no log and is not a container', () async {
    final bytes = (await from.export(contestId, redact: true)).bytes;

    expect(isSupportBundle(bytes), isFalse);
  });

  test('an imported copy is listed as inspection and not synced', () async {
    final bytes = (await from.export(contestId, redact: true)).bytes;

    final preview = await to.preview(bytes);
    expect(preview.contestName, 'Sent: Spring/Fling?');
    expect(preview.canImport, isTrue);
    expect(preview.available, contains(ExchangeImportMode.inspection));

    final imported = await to.import(bytes, ExchangeImportMode.inspection);

    expect(imported.contestId, contestId);
    expect(await to.inspectionContests(), {contestId});
    expect(await from.inspectionContests(), isEmpty);
  });

  test('a second import of the same file is refused with the name', () async {
    final bytes = (await from.export(contestId, redact: true)).bytes;
    await to.import(bytes, ExchangeImportMode.inspection);

    final preview = await to.preview(bytes);

    expect(preview.canImport, isFalse);
    expect(preview.existingCopyName, 'Sent: Spring/Fling?');
    expect(preview.refusals.single, contains('already in this database'));
    await expectLater(
      to.import(bytes, ExchangeImportMode.inspection),
      throwsA(isA<ExchangeFailure>()),
    );
  });

  test('an editable copy is not listed as inspection', () async {
    final bytes = (await from.export(contestId, redact: true)).bytes;

    await to.import(bytes, ExchangeImportMode.editable);

    expect(await to.inspectionContests(), isEmpty);
  });

  test('something that is not a contest file is explained', () async {
    await expectLater(
      to.preview(Uint8List.fromList('hello'.codeUnits)),
      throwsA(isA<ExchangeFailure>()),
    );
  });
}
