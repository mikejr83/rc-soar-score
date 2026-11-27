import 'dart:async';

import 'package:web/web.dart' as web;

/// Tries to close the browser tab. If the tab does not close (it was opened
/// by direct link, not by script), falls back to [onClosed].
Future<void> closeWindowOrFallback(Future<void> Function() onClosed) async {
  web.window.close();
  // Wait briefly to give the window a chance to close. If window.close()
  // succeeds, the document is destroyed and this function never reaches
  // the fallback. If it fails (e.g., tab opened by direct link), the
  // fallback runs.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await onClosed();
}
