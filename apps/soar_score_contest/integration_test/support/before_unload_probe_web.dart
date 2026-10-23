import 'package:web/web.dart' as web;

/// Fires a cancelable `beforeunload` at the page, as the browser does when the
/// tab closes, and reports whether the app cancelled it (the browser would
/// then show its leave-page prompt). Headless Chrome shows no prompt itself,
/// so this is the observable part.
bool? closeWouldBeBlocked() {
  final event = web.Event('beforeunload', web.EventInit(cancelable: true));
  return !web.window.dispatchEvent(event);
}
