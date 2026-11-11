import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router.dart';
import '../../../services/workspace/workspace_control.dart';
import '../../publication/publication_actions_row.dart';
import '../../publication/publication_text.dart';
import '../workspace_scope.dart';
import 'control_card_body.dart';

/// The publication card of the workspace: whether and how the contest is
/// published, the public update policy (read only, with a link to
/// Configuration) and the publish and visibility actions.
class PublicationControlCard extends StatelessWidget {
  const PublicationControlCard({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = WorkspaceScope.of(context);
    final facts = scope.facts;
    if (facts == null) {
      return ControlCardBody(
        control: WorkspaceControl.publication,
        current: l10n.publicationStateUnknown,
        scope: l10n.publicationScopeUnpublished,
        disabledReason: l10n.publicationUnknownReason,
        button: scope.factsFailed
            ? TextButton(
                key: const ValueKey('publication-retry'),
                onPressed: scope.reloadFacts,
                child: Text(l10n.publicationActionRetry),
              )
            : const SizedBox.shrink(),
      );
    }
    final publication = facts.publication;
    final policy = facts.options?.publicUpdateMode;
    final at = publication.projection?.publishedAt ?? publication.publishedAt;
    final reason = PublicationActionsRow.disabledReason(
      l10n,
      publication,
      isOffline: facts.isOffline,
    );
    return ControlCardBody(
      control: WorkspaceControl.publication,
      current: l10n.publicationState(publication),
      scope: publication.isPublished
          ? [
              if (at != null)
                l10n.publicationScopePublished(l10n.publicationTime(at)),
              l10n.updatePolicy(policy),
            ].join(' ')
          : l10n.publicationScopeUnpublished,
      disabledReason: reason,
      button: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PublicationActionsRow(
            contest: contest,
            publication: publication,
            policyText: l10n.updatePolicy(policy),
            isOffline: facts.isOffline,
            onChanged: scope.reloadFacts,
          ),
          if (publication.isPublished)
            TextButton(
              key: const ValueKey('publication-change-policy'),
              onPressed: () =>
                  context.go(contestConfigurationPath(contest.id.value)),
              child: Text(l10n.publicationChangePolicy),
            ),
          TextButton(
            key: const ValueKey('publication-open-page'),
            onPressed: () =>
                context.go(contestPublicationPath(contest.id.value)),
            child: Text(l10n.publicationActionOpenPage),
          ),
        ],
      ),
    );
  }
}
