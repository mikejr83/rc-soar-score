import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soar_score_contest/platform/native_bootstrap.dart';

void main() {
  late Directory root;
  late Directory localData;

  setUp(() {
    root = Directory.systemTemp.createTempSync('native_bootstrap_test');
    localData = Directory(p.join(root.path, '.local-data'));
    addTearDown(() => root.delete(recursive: true));
  });

  test(
    'databasePath uses and creates an overridden local data directory',
    () async {
      final path = await NativeBootstrap.databasePath(
        localDataDirectory: localData.path,
      );

      expect(localData.existsSync(), isTrue);
      expect(p.equals(p.dirname(path), localData.path), isTrue);
      expect(p.basename(path), NativeBootstrap.standardDatabaseName);
    },
  );

  test(
    'databasePath names the demo database in the overridden directory',
    () async {
      final path = await NativeBootstrap.databasePath(
        demo: true,
        localDataDirectory: localData.path,
      );

      expect(p.equals(p.dirname(path), localData.path), isTrue);
      expect(p.basename(path), NativeBootstrap.demoDatabaseName);
    },
  );
}
