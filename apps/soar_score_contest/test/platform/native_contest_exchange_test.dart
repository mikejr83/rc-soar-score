import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
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
