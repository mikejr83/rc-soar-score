/// Why the last sync of a scope did not complete, in the words the director
/// sees. Mirrors the engine's failure kinds so no screen needs the engine.
enum SyncProblem {
  offline(
    'Offline',
    'The remote service could not be reached. Your changes are safe on this '
        'device and will be sent when the connection returns.',
  ),
  signInExpired(
    'Sign in again',
    'Your sign-in has expired. Sign in again to resume syncing. Nothing on '
        'this device was lost.',
  ),
  serverError(
    'Service error',
    'The remote service answered with an error. Syncing will be retried.',
  ),
  updateRequired(
    'Update required',
    'This version of the app is too old to sync. Update it to continue. '
        'Nothing on this device was lost.',
  ),
  inactiveInstallation(
    'Installation not active',
    'This installation is no longer allowed to send changes for this '
        'contest. You can still read and export it.',
  ),
  accountClaimBlocked(
    'Account not linked',
    'Your offline data could not be moved into your account because your '
        'account already has a role, model or setting with the same name. '
        'Rename the duplicate on this device, then sign in again. Nothing on '
        'this device was changed or lost.',
  ),
  accountMismatch(
    'Different account',
    'The data on this computer belongs to another account, so it is not '
        'shown while you are signed in as someone else. Sign out and sign in '
        'as that account, or use a different Windows user. Nothing on this '
        'device was changed or lost.',
  ),
  accountClaimFailed(
    'Account not linked',
    'Your offline data could not be linked to your account. Nothing on this '
        'device was changed or lost. Sign in again to retry.',
  ),
  unsupportedChange(
    'Update required',
    'The service sent a change this version cannot store. Update the app to '
        'continue. Nothing on this device was lost.',
  );

  const SyncProblem(this.label, this.explanation);

  /// A few words for the status area.
  final String label;

  /// A sentence or two for the details page.
  final String explanation;
}
