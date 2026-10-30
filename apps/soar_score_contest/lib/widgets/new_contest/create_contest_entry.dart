import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// How the entry points to the New Contest wizard read: `Create contest`
/// until a draft is underway, then `Continue configuration`.
abstract final class CreateContestEntry {
  static String label(AppLocalizations l10n, bool hasDraft) =>
      hasDraft ? l10n.continueConfigurationLabel : l10n.createContestLabel;

  static IconData icon(bool hasDraft) => hasDraft ? Icons.edit_note : Icons.add;
}
