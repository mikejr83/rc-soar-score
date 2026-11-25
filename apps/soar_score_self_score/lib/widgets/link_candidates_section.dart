import 'package:material_ui/material_ui.dart';

import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/link_candidate.dart';
import 'is_this_you_card.dart';

/// The "Is this you?" cards of the signed-in account, one per pilot its
/// verified email matches. Loads its own list, so a failure here never takes
/// the contests page with it; a confirmed card calls [onLinked] so the page
/// can show the contests the link brings.
class LinkCandidatesSection extends StatefulWidget {
  const LinkCandidatesSection({this.onLinked, super.key});

  final VoidCallback? onLinked;

  @override
  State<LinkCandidatesSection> createState() => _LinkCandidatesSectionState();
}

class _LinkCandidatesSectionState extends State<LinkCandidatesSection>
    with AutomaticKeepAliveClientMixin {
  Future<List<LinkCandidate>>? _future;
  Object? _repository;
  final _answered = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.repository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.linkCandidates();
    }
  }

  void _retry() {
    setState(() {
      _future = context.repository.linkCandidates();
    });
  }

  // The section is a lazy list child: a confirmation that finishes after it
  // scrolls away must still reach the page so the new contest shows up.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<List<LinkCandidate>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.isThisYouLoadFailed,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(onPressed: _retry, child: Text(l10n.isThisYouRetry)),
              ],
            ),
          );
        }
        final shown = [
          for (final candidate in snapshot.data ?? const <LinkCandidate>[])
            if (!_answered.contains(candidate.id)) candidate,
        ];
        if (shown.isEmpty) return const SizedBox.shrink();
        final repository = context.repository;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final candidate in shown) ...[
              IsThisYouCard(
                key: ValueKey(candidate.id),
                candidate: candidate,
                onConfirm: () async {
                  await repository.confirmLinkCandidate(candidate.id);
                  if (!mounted) return;
                  setState(() => _answered.add(candidate.id));
                  widget.onLinked?.call();
                },
                onDecline: () async {
                  await repository.declineLinkCandidate(candidate.id);
                  if (!mounted) return;
                  setState(() => _answered.add(candidate.id));
                },
                onGone: () {
                  if (mounted) setState(() => _answered.add(candidate.id));
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}
