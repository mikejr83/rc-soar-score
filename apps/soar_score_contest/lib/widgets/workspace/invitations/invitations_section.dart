import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../api_client_provider.dart';
import '../../../connectivity_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router.dart';
import '../../../services/reports/pilot_cards/pilot_invitations.dart';
import '../../../services/reports/report_kind.dart';
import '../../invitations/send_invitations_flow.dart';
import '../../sync/reload_on_sync.dart';

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

  /// Counts the loads started; a result of an earlier one is dropped.
  int _generation = 0;

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
    final generation = ++_generation;
    final client = apiClientOf(context);
    final publication = publicationClientOf(context);
    if (client == null || publication == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    // A reload with a card already showing keeps it on screen.
    if (_session == null) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final participations = await client.participations(widget.contest.id);
      final session = await PilotInvitationSession.open(
        source: PilotInvitationSources.current,
        client: publication,
        contestId: widget.contest.id,
      );
      if (!mounted || generation != _generation) {
        session.dispose();
        return;
      }
      _session?.removeListener(_changed);
      _session?.dispose();
      setState(() {
        _pilots = [
          for (final p in participations)
            if (canHaveInvitation(p)) p.id,
        ];
        _session = session..addListener(_changed);
        _loading = false;
        _failed = session.phase == InvitationPhase.loadFailed;
      });
    } on Object {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Connectivity is read again whenever it changes, so the button goes off
    // with the reason instead of failing a request.
    final monitor = appConnectivityOf(context);
    // A sync can change whether invitations may be sent (the contest reaches
    // the server) and who has a link, so the card reads them again.
    return ReloadOnSync(
      scope: ContestScopeKey(widget.contest.id),
      onSynced: () => unawaited(_load()),
      child: monitor == null
          ? Builder(builder: _card)
          : ListenableBuilder(
              listenable: monitor,
              builder: (context, _) => _card(context),
            ),
    );
  }

  Widget _card(BuildContext context) {
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
        : invitationsUnavailableText(
            l10n,
            session.invitations,
            unreachable: invitationsUnreachableText(context, l10n),
          );
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
                            await sendInvitationsGuarded(
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
