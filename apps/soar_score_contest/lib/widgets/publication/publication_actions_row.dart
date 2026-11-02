import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/workspace/publication_facts.dart';
import 'publication_flow.dart';

/// The publish and visibility buttons for one contest, shared by the
/// workspace card and the Publication page. Disabled with a reason when the
/// server cannot be reached or does not publish; calls [onChanged] after a
/// successful change.
class PublicationActionsRow extends StatefulWidget {
  const PublicationActionsRow({
    super.key,
    required this.contest,
    required this.publication,
    required this.policy,
    required this.isOffline,
    required this.onChanged,
  });

  final Contest contest;
  final PublicationFacts publication;
  final PublicUpdateMode? policy;
  final bool isOffline;
  final VoidCallback onChanged;

  /// Why the actions are disabled, or null when they are available.
  static String? disabledReason(
    AppLocalizations l10n,
    PublicationFacts publication, {
    required bool isOffline,
  }) {
    if (!publication.isKnown) {
      return l10n.publicationUnknownReason;
    }
    if (!publication.supported) {
      return l10n.publicationUnavailableReason;
    }
    return isOffline ? l10n.publicationNeedsConnection : null;
  }

  @override
  State<PublicationActionsRow> createState() => _PublicationActionsRowState();
}

class _PublicationActionsRowState extends State<PublicationActionsRow> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    try {
      final changed = await action();
      if (changed) {
        widget.onChanged();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final publication = widget.publication;
    final available =
        PublicationActionsRow.disabledReason(
          l10n,
          publication,
          isOffline: widget.isOffline,
        ) ==
        null;
    final enabled = available && !_busy;
    final visibility = publication.visibility;
    final delisted = visibility == PublicationVisibility.delisted;
    final canSwitch = publication.isPublished && !delisted;
    final target = visibility == PublicationVisibility.public
        ? PublicationVisibility.unlisted
        : PublicationVisibility.public;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!delisted)
          FilledButton.icon(
            key: const ValueKey('publication-publish'),
            onPressed: enabled
                ? () => _run(
                    () => PublicationFlow.publish(
                      context,
                      contest: widget.contest,
                      publication: publication,
                      policy: widget.policy,
                    ),
                  )
                : null,
            icon: const Icon(Icons.public),
            label: Text(
              publication.isPublished
                  ? l10n.publicationActionUpdate
                  : l10n.publicationActionPublish,
            ),
          ),
        if (canSwitch)
          OutlinedButton(
            key: const ValueKey('publication-visibility'),
            onPressed: enabled
                ? () => _run(
                    () => PublicationFlow.changeVisibility(
                      context,
                      contestId: widget.contest.id,
                      target: target,
                    ),
                  )
                : null,
            child: Text(
              target == PublicationVisibility.public
                  ? l10n.publicationActionMakePublic
                  : l10n.publicationActionMakeUnlisted,
            ),
          ),
      ],
    );
  }
}
