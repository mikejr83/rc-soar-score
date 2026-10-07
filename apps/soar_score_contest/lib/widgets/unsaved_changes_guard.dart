/// Lets a route's `onExit` ask the page it shows whether leaving is fine.
///
/// A page with unsaved edits attaches itself while it is mounted; the router
/// calls [confirmLeave] before any navigation away from the route (rail,
/// breadcrumbs, links), not only the page's own Cancel button or the back
/// gesture.
class UnsavedChangesGuard {
  Future<bool> Function()? _confirm;

  /// Registers [confirm], which returns whether the page may be left (asking
  /// the user when there are unsaved changes).
  void attach(Future<bool> Function() confirm) => _confirm = confirm;

  /// Unregisters [confirm] if it is still the attached one.
  void detach(Future<bool> Function() confirm) {
    if (_confirm == confirm) {
      _confirm = null;
    }
  }

  /// Whether the current page may be left.
  Future<bool> confirmLeave() async => await _confirm?.call() ?? true;
}
