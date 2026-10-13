import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/installation_id_file.dart';

void main() {
  late Directory dir;
  late InstallationIdFile idFile;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('installation_id_test');
    idFile = InstallationIdFile.besides('${dir.path}/soar_score.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('creates an identifier once and returns it afterwards', () async {
    final first = await idFile.readOrCreate();
    final second = await idFile.readOrCreate();

    expect(second, first);
  });

  test('replaces a damaged file', () async {
    await idFile.file.writeAsString('not an id');

    final id = await idFile.readOrCreate();

    expect(await idFile.readOrCreate(), id);
  });
}
