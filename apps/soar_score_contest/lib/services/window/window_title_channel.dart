import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sets the Windows desktop window's title bar text.
///
/// Stable Flutter does not apply titles to Windows desktop windows, so the
/// runner exposes `setTitle` on the `soar_score/window` channel
/// (`windows/runner/window_title_channel.cpp`). Every other platform is a
/// no-op; the web tab title comes from the `Title` widget instead.
abstract final class WindowTitleChannel {
  static const MethodChannel channel = MethodChannel('soar_score/window');

  static Future<void> setTitle(String title) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }
    try {
      await channel.invokeMethod<void>('setTitle', title);
    } on MissingPluginException {
      // Hosts without the runner channel (e.g. widget tests) keep their title.
    }
  }
}
