import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../widgets/unsaved_changes_guard.dart';
import 'window_title_channel.dart';

/// Answers the Windows runner when the user closes the window.
///
/// On `WM_CLOSE` the runner (`windows/runner/window_title_channel.cpp`) calls
/// `confirmClose` on the `soar_score/window` channel and closes only when this
/// returns `true`. A page with unsaved edits asks the user with its own
/// discard dialog. Other native platforms have no runner hook and do nothing.
void installCloseWarning() {
  if (defaultTargetPlatform != TargetPlatform.windows) {
    return;
  }
  WindowTitleChannel.channel.setMethodCallHandler((call) async {
    if (call.method != 'confirmClose') {
      throw MissingPluginException(call.method);
    }
    return UnsavedChangesGuard.confirmCloseAll();
  });
}
