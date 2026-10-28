import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for `flutter drive` runs of `integration_test/` on the web
/// (`scripts/e2e.sh -d web`); the Windows runs use `flutter test`.
///
/// Screenshots a journey takes on failure (`Journey`) are saved in
/// `build/e2e-screenshots/`.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('build/e2e-screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
