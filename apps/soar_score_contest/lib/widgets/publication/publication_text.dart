import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/publication/publication_actions.dart';
import '../../services/workspace/publication_facts.dart';

/// The words of the publication card, dialogs and page, in the app's language.
extension PublicationText on AppLocalizations {
  String visibilityName(PublicationVisibility visibility) =>
      switch (visibility) {
        PublicationVisibility.unlisted => publicationVisibilityUnlisted,
        PublicationVisibility.public => publicationVisibilityPublic,
        PublicationVisibility.delisted => publicationVisibilityDelisted,
      };

  /// The current state line: Unpublished, Published and its visibility, or
  /// why the state is not known.
  String publicationState(PublicationFacts facts) {
    if (facts.needsSignIn) {
      return publicationStateSignIn;
    }
    if (!facts.isKnown) {
      return publicationStateUnknown;
    }
    if (!facts.supported) {
      return publicationStateUnavailable;
    }
    final visibility = facts.visibility;
    if (!facts.isPublished || visibility == null) {
      return publicationStateUnpublished;
    }
    return facts.delistPending
        ? publicationStatePublishedDelistPending(visibilityName(visibility))
        : publicationStatePublished(visibilityName(visibility));
  }

  String updatePolicy(PublicUpdateMode? mode) => switch (mode) {
    PublicUpdateMode.automatic => publicationPolicyAutomatic,
    PublicUpdateMode.roundCompletion => publicationPolicyRoundCompletion,
    PublicUpdateMode.manual => publicationPolicyManual,
    null => publicationPolicyUnknown,
  };

  String publicationFailure(PublicationFailure failure) => switch (failure) {
    PublicationFailure.staleContest => publicationFailStaleContest,
    PublicationFailure.staleResults => publicationFailStaleResults,
    PublicationFailure.notReady => publicationFailNotReady,
    PublicationFailure.delisted => publicationFailDelisted,
    PublicationFailure.unavailable => publicationFailUnavailable,
    PublicationFailure.notPublic => publicationFailNotPublic,
    PublicationFailure.nothingPending => publicationFailNothingPending,
    PublicationFailure.notDirector => publicationFailNotDirector,
    PublicationFailure.signInRequired => publicationFailSignIn,
    PublicationFailure.signInExpired => publicationFailSignInExpired,
    PublicationFailure.notSynced => publicationFailNotSynced,
    PublicationFailure.network => publicationFailNetwork,
    PublicationFailure.other => publicationFailOther,
  };

  /// [time] in the viewer's zone, for example `Nov 2, 2026, 3:30 PM`.
  String publicationTime(DateTime time) =>
      DateFormat.yMMMd(localeName).add_jm().format(time.toLocal());
}
