import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/window/window_title_channel.dart';

/// Run a test as Windows desktop with `variant: windowsOnly`.
final TargetPlatformVariant windowsOnly = TargetPlatformVariant.only(
  TargetPlatform.windows,
);

/// Records the titles sent to the runner's window channel. Undone
/// automatically at the end of the test.
List<String> recordWindowTitles() {
  final titles = <String>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(WindowTitleChannel.channel, (call) async {
    if (call.method == 'setTitle') {
      titles.add(call.arguments as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(WindowTitleChannel.channel, null),
  );
  return titles;
}
