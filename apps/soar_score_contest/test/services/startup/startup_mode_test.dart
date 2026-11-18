import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/startup/startup_mode.dart';
import 'package:soar_score_contest/services/startup/startup_splash_store.dart';
import 'package:soar_score_data/soar_score_data.dart';

void main() {
  group('startupModeFor', () {
    test('no database is a first run', () {
      expect(
        startupModeFor(storedVersion: null, currentVersion: 2),
        StartupMode.initializing,
      );
    });
    test('an older database is an update', () {
      expect(
        startupModeFor(storedVersion: 1, currentVersion: 2),
        StartupMode.updating,
      );
    });
    test('a current database is a normal start', () {
      expect(
        startupModeFor(storedVersion: 2, currentVersion: 2),
        StartupMode.starting,
      );
    });
  });

  test('noSplashRequested reads the environment variable', () {
    expect(noSplashRequested(null), isFalse);
    expect(noSplashRequested(''), isFalse);
    expect(noSplashRequested('0'), isFalse);
    expect(noSplashRequested('false'), isFalse);
    expect(noSplashRequested('1'), isTrue);
    expect(noSplashRequested('true'), isTrue);
  });

  group('with a directory', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('startup_mode'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('readLocalSchemaVersion is null without a database', () {
      expect(readLocalSchemaVersion(File('${dir.path}/none.db')), isNull);
      final empty = File('${dir.path}/empty.db')..writeAsBytesSync([]);
      expect(readLocalSchemaVersion(empty), isNull);
    });

    test(
      'readLocalSchemaVersion reads the version of a created database',
      () async {
        final file = File('${dir.path}/soar_score.db');
        final db = createLocalDatabase(file, inBackground: false);
        await db.customSelect('SELECT 1').get();
        await db.close();
        expect(
          readLocalSchemaVersion(file),
          SoarScoreDatabase.currentSchemaVersion,
        );
      },
    );

    test('the splash marker switches it off and on', () async {
      final store = StartupSplashStore(dir.path);
      expect(store.enabled, isTrue);
      await store.setEnabled(false);
      expect(StartupSplashStore(dir.path).enabled, isFalse);
      await store.setEnabled(true);
      expect(StartupSplashStore(dir.path).enabled, isTrue);
    });
  });
}
