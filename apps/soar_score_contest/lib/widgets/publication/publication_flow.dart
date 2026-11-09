import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../auth/auth_session_inherited.dart';
import '../../l10n/app_localizations.dart';
import '../../services/publication/publication_actions.dart';
import '../../services/workspace/publication_facts.dart';
import 'publication_dialogs.dart';
import 'publication_text.dart';

/// The publish and visibility flows shared by the workspace card and the
/// Publication page: confirm, call the API, say what happened.
abstract final class PublicationFlow {
  static bool _signedIn(BuildContext context) =>
      authSessionOf(context)?.isSignedIn ?? false;

  /// Confirms and publishes [contest]; true when it was published.
  ///
  /// The visibility shown in the dialog is the current one, or Unlisted for a
  /// first publish.
  static Future<bool> publish(
    BuildContext context, {
    required Contest contest,
    required PublicationFacts publication,
    required String policyText,
  }) async {
    final client = publicationClientOf(context);
    final signedIn = _signedIn(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (client == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.publicationFailOther)),
      );
      return false;
    }
    final confirmed = await confirmPublish(
      context,
      contest: contest,
      visibility: publication.visibility ?? PublicationVisibility.unlisted,
      policyText: policyText,
    );
    if (!confirmed) {
      return false;
    }
    final outcome = await PublicationActions(client, signedIn: signedIn)
        .publish(
          contest,
          projectionRevision: publication.projection?.projectionRevision ?? 0,
        );
    _report(messenger, l10n, outcome, l10n.publicationPublishedDone);
    return outcome.succeeded;
  }

  /// Switches the publication of [contestId] to [target]; asks first when it
  /// becomes Public. True when it changed.
  static Future<bool> changeVisibility(
    BuildContext context, {
    required Id contestId,
    required PublicationVisibility target,
  }) async {
    final client = publicationClientOf(context);
    final signedIn = _signedIn(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (client == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.publicationFailOther)),
      );
      return false;
    }
    if (target == PublicationVisibility.public &&
        !await confirmMakePublic(context)) {
      return false;
    }
    final outcome = await PublicationActions(
      client,
      signedIn: signedIn,
    ).setVisibility(contestId, target);
    _report(
      messenger,
      l10n,
      outcome,
      l10n.publicationVisibilityDone(l10n.visibilityName(target)),
    );
    return outcome.succeeded;
  }

  /// Confirms and asks to delist the publication of [contestId]; true when
  /// the request was made.
  static Future<bool> requestDelisting(
    BuildContext context, {
    required Id contestId,
  }) async {
    final client = publicationClientOf(context);
    final signedIn = _signedIn(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (client == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.publicationFailOther)),
      );
      return false;
    }
    final reason = await confirmRequestDelisting(context);
    if (reason == null) {
      return false;
    }
    final outcome = await PublicationActions(
      client,
      signedIn: signedIn,
    ).requestDelisting(contestId, reason: reason.isEmpty ? null : reason);
    _report(messenger, l10n, outcome, l10n.publicationDelistRequestedDone);
    return outcome.succeeded;
  }

  /// Withdraws the pending delisting request; true when it was withdrawn. A
  /// request that is no longer pending is reported and counts as a change,
  /// so the caller reads the publication again.
  static Future<bool> withdrawDelisting(
    BuildContext context, {
    required Id contestId,
  }) async {
    final client = publicationClientOf(context);
    final signedIn = _signedIn(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (client == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.publicationFailOther)),
      );
      return false;
    }
    final outcome = await PublicationActions(
      client,
      signedIn: signedIn,
    ).withdrawDelisting(contestId);
    _report(messenger, l10n, outcome, l10n.publicationDelistWithdrawnDone);
    return outcome.succeeded ||
        outcome.failure == PublicationFailure.nothingPending;
  }

  static void _report(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    PublicationOutcome outcome,
    String done,
  ) {
    final failure = outcome.failure;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? done : l10n.publicationFailure(failure),
        ),
      ),
    );
  }
}
