import 'dart:async';

import 'package:web/web.dart' as web;

/// Tries to close the browser tab. If the tab does not close (it was opened
/// by direct link, not by script), falls back to [onClosed].
Future<void> closeWindowOrFallback(Future<void> Function() onClosed) async {
  web.window.close();
  // The window.closed property is not available in package:web yet.
  // Instead, wait briefly and check if we're still alive.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  if (!web.document.hidden) {
    // Still alive: the window did not close, so run the fallback.
    await onClosed();
  }
}
