import 'dart:async';

/// On native, there is no separate window to close; run the fallback directly.
Future<void> closeWindowOrFallback(Future<void> Function() onClosed) async {
  await onClosed();
}
