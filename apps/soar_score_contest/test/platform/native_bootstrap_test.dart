import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/native_bootstrap.dart';

void main() {
  test(
    'databasePath uses and creates an overridden local data directory',
    () async {
      final root = Directory.systemTemp.createTempSync('native_bootstrap_test');
      final localData = Directory('${root.path}/.local-data');
      addTearDown(() => root.delete(recursive: true));

      final path = await NativeBootstrap.databasePath(
        localDataDirectory: localData.path,
      );

      expect(localData.existsSync(), isTrue);
      expect(File(path).parent.path, localData.path);
      expect(File(path).uri.pathSegments.last, 'soar_score.db');
    },
  );
}
