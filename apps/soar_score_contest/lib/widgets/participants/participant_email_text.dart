import '../../l10n/app_localizations.dart';
import '../../services/participants/participant_row.dart';

/// The words for a [ParticipantEmailStatus].
extension ParticipantEmailText on ParticipantEmailStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ParticipantEmailStatus.has => l10n.participantEmailHas,
    ParticipantEmailStatus.none => l10n.participantEmailNone,
    ParticipantEmailStatus.private => l10n.participantEmailPrivate,
  };

  String explanation(AppLocalizations l10n) => switch (this) {
    ParticipantEmailStatus.has => l10n.participantEmailHasExplanation,
    ParticipantEmailStatus.none => l10n.participantEmailNoneExplanation,
    ParticipantEmailStatus.private => l10n.participantEmailPrivateExplanation,
  };
}
