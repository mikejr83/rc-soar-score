import 'dart:io';

import 'package:path/path.dart' as p;

import 'startup_splash_control.dart';

/// Remembers whether the startup splash is switched off, in a marker file
/// beside the database: the splash is shown before any database or saved
/// preference is loaded, so the choice cannot live in either.
class StartupSplashStore implements StartupSplashControl {
  StartupSplashStore(String directory)
    : _marker = File(p.join(directory, markerName));

  static const String markerName = 'startup_splash_off';

  final File _marker;

  /// Whether the splash is on (the default).
  @override
  bool get enabled => !_marker.existsSync();

  @override
  Future<void> setEnabled(bool value) async {
    if (value) {
      if (_marker.existsSync()) await _marker.delete();
    } else {
      await _marker.create(recursive: true);
    }
  }
}
