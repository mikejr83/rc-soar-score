import 'package:material_ui/material_ui.dart';

import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/past_contests.dart';
import '../public_site.dart';
import '../services/contest_dates.dart';

/// The signed-in pilot's finished contests, newest first, a page at a time
/// (#1048). Loads its own list, so a failure here never takes the page it sits
/// on with it. Each contest with public results links to them.
class PastContestsSection extends StatefulWidget {
  const PastContestsSection({this.opener = openInBrowser, super.key});

  /// Opens a public results address.
  final UrlOpener opener;

  @override
  State<PastContestsSection> createState() => _PastContestsSectionState();
}

class _PastContestsSectionState extends State<PastContestsSection> {
  final _contests = <PastContest>[];
  Object? _repository;

  /// The offset of the next page; null when the last one is in.
  int? _next = 0;
  bool _loading = false;
  bool _failed = false;

  /// Bumped when the repository changes, so an answer to an older request is
  /// dropped.
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.repository;
    if (_repository != repository) {
      _repository = repository;
      _generation++;
      _contests.clear();
      _next = 0;
      _failed = false;
      _loading = false;
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final offset = _next;
    if (offset == null || _loading) return;
    final generation = _generation;
    final repository = context.repository;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await repository.pastContests(offset: offset);
      if (!mounted || generation != _generation) return;
      setState(() {
        _contests.addAll(page.contests);
        _next = page.nextOffset;
        _loading = false;
      });
    } on SelfScoreLoadException {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toString();
    final firstLoad = _loading && _contests.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.pastContestsTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        Text(
          l10n.pastContestsNote,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 8),
        if (firstLoad)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_contests.isEmpty && !_failed)
          Text(
            l10n.pastContestsEmpty,
            style: theme.textTheme.bodyLarge?.copyWith(color: muted),
          ),
        for (final contest in _contests) ...[
          _PastContestCard(
            contest: contest,
            dates: formatContestDates(
              l10n,
              locale,
              contest.startDate,
              contest.endDate,
            ),
            onOpenResults: contest.publicResultsUrl == null
                ? null
                : () => openLinkOrExplain(
                    context,
                    contest.publicResultsUrl!,
                    opener: widget.opener,
                  ),
          ),
          const SizedBox(height: 8),
        ],
        if (_failed)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pastContestsLoadFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
              TextButton(
                onPressed: _loadMore,
                child: Text(l10n.pastContestsRetry),
              ),
            ],
          )
        else if (_next != null && _contests.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _loading ? null : _loadMore,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.pastContestsShowMore),
            ),
          ),
      ],
    );
  }
}

class _PastContestCard extends StatelessWidget {
  const _PastContestCard({
    required this.contest,
    required this.dates,
    required this.onOpenResults,
  });

  final PastContest contest;
  final String dates;
  final VoidCallback? onOpenResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contest.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              dates,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            if (contest.location != null)
              Text(
                contest.location!,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            if (onOpenResults != null)
              TextButton.icon(
                onPressed: onOpenResults,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.contestPublicResults),
              ),
          ],
        ),
      ),
    );
  }
}
