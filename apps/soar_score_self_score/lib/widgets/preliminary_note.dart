import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/officialization_policy.dart';

/// Explains why the scores on a results page are preliminary: when the
/// contest makes them official, and that an open review holds a score.
class PreliminaryNote extends StatelessWidget {
  const PreliminaryNote({
    super.key,
    required this.policy,
    required this.showReviewHold,
  });

  /// When the contest makes scores official; null when unknown.
  final OfficializationPolicy? policy;

  /// Whether to add that a review holds a score.
  final bool showReviewHold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = switch (policy) {
      OfficializationPolicy.endOfRound => l10n.preliminaryNoteEndOfRound,
      OfficializationPolicy.endOfGroup => l10n.preliminaryNoteEndOfGroup,
      OfficializationPolicy.manual => l10n.preliminaryNoteManual,
      null => l10n.preliminaryNoteGeneral,
    };
    return Text(
      showReviewHold ? '$text ${l10n.preliminaryNoteReviewHold}' : text,
      key: const ValueKey('preliminary-note'),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
