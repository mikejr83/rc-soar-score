import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/self_score_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/link_candidate.dart';
import '../services/contest_dates.dart';

/// Asks a signed-in person to confirm the pilot their email matches.
///
/// [onConfirm] and [onDecline] send the answer; a [LinkCandidateGoneException]
/// from either means the match no longer stands, so the card says why and
/// [onGone] takes it away. Any other failure leaves the card in place with an
/// error, so the answer can be sent again.
class IsThisYouCard extends StatefulWidget {
  const IsThisYouCard({
    required this.candidate,
    required this.onConfirm,
    required this.onDecline,
    required this.onGone,
    super.key,
  });

  final LinkCandidate candidate;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onDecline;
  final VoidCallback onGone;

  @override
  State<IsThisYouCard> createState() => _IsThisYouCardState();
}

class _IsThisYouCardState extends State<IsThisYouCard> {
  bool _busy = false;

  /// The server refused for good and the card is about to go: no more
  /// answers, so a second request cannot race the dismissal.
  bool _gone = false;
  String? _error;
  Timer? _dismissal;

  @override
  void dispose() {
    // A card removed while its reason is showing (the pilot left the page or
    // signed out) must not call back into a widget that is gone.
    _dismissal?.cancel();
    super.dispose();
  }

  Future<void> _answer(Future<void> Function() send) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await send();
    } on LinkCandidateGoneException catch (error) {
      if (!mounted) return;
      setState(() {
        _gone = true;
        _busy = false;
        _error = switch (error.reason) {
          LinkCandidateGoneReason.alreadyLinked => AppLocalizations.of(
            context,
          ).isThisYouAlreadyLinked,
          LinkCandidateGoneReason.notAvailable => AppLocalizations.of(
            context,
          ).isThisYouNoLongerAvailable,
        };
      });
      // Leave the reason on screen long enough to read, then drop the card.
      _dismissal = Timer(const Duration(seconds: 3), widget.onGone);
    } on SelfScoreLoadException {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).isThisYouFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final candidate = widget.candidate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person_search_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.isThisYouTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.isThisYouMatches(candidate.pilotName),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      for (final contest in candidate.contests)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.isThisYouContest(
                              contest.name,
                              formatContestDates(
                                l10n,
                                Localizations.localeOf(context).toString(),
                                contest.startDate,
                                contest.endDate,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _busy || _gone
                        ? null
                        : () => _answer(widget.onConfirm),
                    child: Text(l10n.isThisYouConfirm),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: scheme.onSurface, width: 1.5),
                    ),
                    onPressed: _busy || _gone
                        ? null
                        : () => _answer(widget.onDecline),
                    child: Text(l10n.isThisYouDecline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
