import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../api_client_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router.dart';
import '../../../services/reports/pilot_cards/pilot_invitations.dart';
import '../../../services/reports/report_kind.dart';
import '../../invitations/send_invitations_flow.dart';

/// The workspace card under the setup checklist that sends pilot invitations:
/// the same send as the pilot cards report, without opening it. Issuing never
/// emails; the QR codes are printed on the cards.
class InvitationsSection extends StatefulWidget {
  const InvitationsSection({super.key, required this.contest});

  final Contest contest;

  @override
  State<InvitationsSection> createState() => _InvitationsSectionState();
}

class _InvitationsSectionState extends State<InvitationsSection> {
  PilotInvitationSession? _session;
  List<Id> _pilots = const [];
  bool _loading = true;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _session?.removeListener(_changed);
    _session?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final client = apiClientOf(context);
    final publication = publicationClientOf(context);
    if (client == null || publication == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final participations = await client.participations(widget.contest.id);
      final session = await PilotInvitationSession.open(
        source: PilotInvitationSources.current,
        client: publication,
        contestId: widget.contest.id,
      );
      if (!mounted) {
        session.dispose();
        return;
      }
      _session?.removeListener(_changed);
      _session?.dispose();
      setState(() {
        _pilots = [
          for (final p in participations)
            if (p.roleType == RoleType.pilot && p.retiredAtRound == null) p.id,
        ];
        _session = session..addListener(_changed);
        _loading = false;
        _failed = session.phase == InvitationPhase.loadFailed;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = _session;
    final missing = session == null
        ? const <Id>[]
        : [
            for (final id in _pilots)
              if (!session.has(id)) id,
          ];
    final reason = session == null
        ? null
        : invitationsUnavailableText(l10n, session.invitations);
    final String text;
    if (_loading) {
      text = l10n.invitationsLoading;
    } else if (_failed || session == null) {
      text = l10n.invitationsLoadFailed;
    } else if (_pilots.isEmpty) {
      text = l10n.invitationsNoPilots;
    } else if (missing.isEmpty) {
      text = l10n.invitationsCoverageAll(_pilots.length);
    } else {
      text = l10n.invitationsCoverage(
        _pilots.length - missing.length,
        _pilots.length,
      );
    }
    final canSend =
        session != null &&
        !session.sending &&
        missing.isNotEmpty &&
        reason == null;
    return Card(
      key: const ValueKey('workspace-invitations'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.qr_code_2),
                Text(
                  l10n.invitationsSectionTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            Text(text, key: const ValueKey('workspace-invitations-text')),
            if (reason != null && missing.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  const Icon(Icons.block, size: 18),
                  Expanded(child: Text(reason)),
                ],
              ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_failed && !_loading)
                  OutlinedButton(
                    key: const ValueKey('workspace-invitations-retry'),
                    onPressed: _load,
                    child: Text(l10n.pilotCardsRetry),
                  )
                else ...[
                  FilledButton.icon(
                    key: const ValueKey('workspace-invitations-send'),
                    onPressed: canSend
                        ? () async {
                            await sendInvitationsWithConfirmation(
                              context,
                              session,
                              missing,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.campaign),
                    label: Text(
                      missing.isEmpty
                          ? l10n.pilotCardsSendAction
                          : l10n.invitationsSendMissing(missing.length),
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('workspace-invitations-cards'),
                    onPressed: () => context.go(
                      contestReportPath(
                        widget.contest.id.value,
                        ReportKind.cards,
                      ),
                    ),
                    child: Text(l10n.invitationsOpenCards),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
