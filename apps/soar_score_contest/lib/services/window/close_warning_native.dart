import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';

import '../../widgets/unsaved_changes_guard.dart';

/// Asks before the desktop window closes while a guarded page has unsaved
/// edits.
///
/// The Flutter engine turns a window close (Windows, `WM_CLOSE`) into a
/// cancelable exit request. A page with unsaved edits asks the user with its
/// own discard dialog, and answering "keep editing" cancels the close.
void installCloseWarning() {
  AppLifecycleListener(
    onExitRequested: () async => await UnsavedChangesGuard.confirmCloseAll()
        ? AppExitResponse.exit
        : AppExitResponse.cancel,
  );
}
