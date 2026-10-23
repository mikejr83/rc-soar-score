import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../widgets/unsaved_changes_guard.dart';

/// Makes the browser ask before the tab or window closes (or the page
/// reloads) while a guarded page has unsaved edits.
///
/// The browser shows only its own generic prompt; the listener cancels the
/// event when there is something to lose and stays quiet otherwise.
void installCloseWarning() {
  web.window.addEventListener(
    'beforeunload',
    ((web.Event event) {
      if (UnsavedChangesGuard.anyUnsavedChanges) {
        event.preventDefault();
        // Older browsers want `returnValue` set before they prompt.
        (event as JSObject).setProperty('returnValue'.toJS, ''.toJS);
      }
    }).toJS,
  );
}
