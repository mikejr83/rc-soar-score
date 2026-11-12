import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/pilot_import/pilot_import.dart';
import '../../services/sync/open_conflict.dart';

/// The two links of a GliderScore pilot the director chooses between: the
/// pilot number, and the participant each device linked it to.
class PilotLinkReview extends StatefulWidget {
  const PilotLinkReview({super.key, required this.conflict, this.participants});

  final OpenConflict conflict;

  /// The participants to name; read from the import store when not given.
  final Future<List<ParticipantProfile>>? participants;

  /// The participant a link payload names, by id.
  static String? participantId(Map<String, Object?>? payload) =>
      payload?['participant_profile_id'] as String?;

  @override
  State<PilotLinkReview> createState() => _PilotLinkReviewState();
}

class _PilotLinkReviewState extends State<PilotLinkReview> {
  late Future<List<ParticipantProfile>> _participants;

  @override
  void initState() {
    super.initState();
    _participants =
        widget.participants ??
        PilotImportStore.current?.existing() ??
        Future.value(const <ParticipantProfile>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conflict = widget.conflict;
    final number = conflict.acceptedPayload?['source_pilot_no'] as int?;
    return FutureBuilder<List<ParticipantProfile>>(
      future: _participants,
      builder: (context, snapshot) {
        String name(Map<String, Object?>? payload) {
          final id = PilotLinkReview.participantId(payload);
          for (final profile in snapshot.data ?? const <ParticipantProfile>[]) {
            if (profile.id.value == id) {
              return '${profile.firstName} ${profile.lastName}';
            }
          }
          return l10n.pilotLinkReviewNoParticipant;
        }

        return Column(
          key: const ValueKey('pilot-link-review'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (number != null)
              Text(
                l10n.pilotLinkReviewTitle(number),
                key: const ValueKey('pilot-link-review-pilot'),
                style: theme.textTheme.titleMedium,
              ),
            const SizedBox(height: 4),
            Text(l10n.pilotLinkReviewIntro),
            const SizedBox(height: 12),
            Text(
              l10n.pilotLinkReviewKept(name(conflict.acceptedPayload)),
              key: const ValueKey('pilot-link-review-kept'),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pilotLinkReviewOther(name(conflict.competingPayload)),
              key: const ValueKey('pilot-link-review-other'),
            ),
          ],
        );
      },
    );
  }
}
