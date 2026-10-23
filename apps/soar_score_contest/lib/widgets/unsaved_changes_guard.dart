/// Lets a route's `onExit` ask the page it shows whether leaving is fine.
///
/// A page with unsaved edits attaches itself while it is mounted; the router
/// calls [confirmLeave] before any navigation away from the route (rail,
/// breadcrumbs, links), not only the page's own Cancel button or the back
/// gesture.
///
/// Every attached guard is also visible to the whole app through
/// [anyUnsavedChanges] and [confirmCloseAll], which the browser tab and the
/// Windows window use to warn before they close.
class UnsavedChangesGuard {
  /// The guards that currently have a page attached.
  static final Set<UnsavedChangesGuard> _attached = {};

  /// Whether any mounted guarded page has unsaved edits right now.
  ///
  /// Synchronous because the browser's `beforeunload` cannot wait for a
  /// dialog.
  static bool get anyUnsavedChanges =>
      _attached.any((guard) => guard._hasChanges?.call() ?? false);

  /// Asks every attached page whether the app may close, stopping at the first
  /// that refuses. Pages without unsaved edits answer without asking.
  static Future<bool> confirmCloseAll() async {
    for (final guard in _attached.toList()) {
      if (!await guard.confirmLeave()) {
        return false;
      }
    }
    return true;
  }

  Future<bool> Function()? _confirm;
  bool Function()? _hasChanges;

  /// Registers [confirm], which returns whether the page may be left (asking
  /// the user when there are unsaved changes). [hasChanges] reports, without
  /// asking, whether the page holds unsaved edits.
  void attach(Future<bool> Function() confirm, {bool Function()? hasChanges}) {
    _confirm = confirm;
    _hasChanges = hasChanges;
    _attached.add(this);
  }

  /// Unregisters [confirm] if it is still the attached one.
  void detach(Future<bool> Function() confirm) {
    if (_confirm == confirm) {
      _confirm = null;
      _hasChanges = null;
      _attached.remove(this);
    }
  }

  /// Whether the current page may be left.
  Future<bool> confirmLeave() async => await _confirm?.call() ?? true;
}
