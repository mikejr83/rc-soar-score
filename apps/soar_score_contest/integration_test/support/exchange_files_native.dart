import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

/// A contest file as another installation would send it: made on a database
/// of its own, with ids the app under test has not seen. The native build's
/// embedded server stands in for the other installation (see
/// `exchange_files_web.dart`).
Future<Uint8List> contestFromAnotherInstallation(String name) async {
  final dir = Directory.systemTemp.createTempSync('e2e_other_installation');
  final server = await startEmbeddedServer('${dir.path}/other.db');
  final client = ApiClient(
    baseUrl: server.baseUrl,
    tokenProvider: () async => server.secret,
  );
  try {
    final id = core.Id.create();
    await client.createContest(
      CreateContestRequest(
        id: id,
        name: name,
        startDateTime: DateTime.utc(2026, 5, 1),
        endDateTime: DateTime.utc(2026, 5, 2),
        timezone: 'America/Denver',
      ),
    );
    return (await NativeContestExchange(server).export(id, redact: true)).bytes;
  } finally {
    client.close();
    await server.close();
    dir.deleteSync(recursive: true);
  }
}
