import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads the version this build was made with (the release workflow passes
/// the tag as `--build-name`).
Future<String> loadAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

/// Replaces the version source in widget tests, where no platform channel
/// answers.
@visibleForTesting
Future<String> Function() appVersionLoader = loadAppVersion;

/// `Version 0.1.0`, or nothing while the version is unknown.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: appVersionLoader(),
      builder: (context, snapshot) {
        final version = snapshot.data;
        if (version == null || version.isEmpty) {
          return const SizedBox.shrink();
        }
        return Text(
          'Version $version',
          key: const ValueKey('app-version'),
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}
