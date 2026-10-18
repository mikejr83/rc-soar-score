import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';

import '../../api_client_provider.dart';
import '../../widgets/results/contest_filter_bar.dart';
import '../../widgets/results/contest_row.dart';
import 'contest_filters.dart';
import 'contest_summary.dart';

/// Loads the Public publication summaries the list is built from.
typedef PublicationLoader =
    Future<List<PublicPublicationSummaryDto>> Function();

/// Contest search at `/results/contests`: the most recent in-progress and
/// completed contests, name, venue and start-date filters carried as query
/// parameters, a 30-day summary and a refresh button.
///
/// Ordering, filtering, the coming-Sunday rule and the summary run
/// client-side over one page of results until #455 moves them to the server.
class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, this.loader, this.clock = DateTime.now});

  static const String title = 'Contests';
  static const String path = '/results/contests';
  static const Key refreshButton = Key('contests_refresh');
  static const Key summaryText = Key('contests_summary');

  /// Number of contests listed when no filter is set.
  static const int defaultCount = 10;

  /// Replaces the API call; tests inject fake data here.
  final PublicationLoader? loader;
  final DateTime Function() clock;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Future<List<ContestSummary>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<ContestSummary>> _load() async {
    final loader =
        widget.loader ??
        // The server caps a page at 100; a longer list waits for #455.
        () => context.apiClient.publicPublications(limit: 100);
    final now = widget.clock();
    return [
      for (final dto in await loader()) ContestSummary.fromDto(dto, now: now),
    ]..sort((a, b) => b.start.compareTo(a.start));
  }

  void _refresh() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  void _applyFilters(ContestFilters filters) => context.go(
    Uri(
      path: ResultsPage.path,
      queryParameters: filters.isEmpty ? null : filters.toQuery(),
    ).toString(),
  );

  void _open(ContestSummary contest) =>
      context.go('${ResultsPage.path}/${contest.publicationId}');

  @override
  Widget build(BuildContext context) {
    final filters = ContestFilters.fromQuery(
      GoRouterState.of(context).uri.queryParameters,
    );
    return FutureBuilder<List<ContestSummary>>(
      future: _future,
      builder: (context, snapshot) {
        final now = widget.clock();
        final visible = [
          for (final c in snapshot.data ?? const <ContestSummary>[])
            if (!c.startsAfterComingSunday(now)) c,
        ];
        final matching = [
          for (final c in visible)
            if (filters.matches(c)) c,
        ];
        final listed = filters.isEmpty
            ? matching.take(ResultsPage.defaultCount).toList()
            : matching;
        final recent = visible.where((c) => c.activeInLast30Days(now)).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ResultsPage.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  key: ResultsPage.refreshButton,
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (snapshot.hasData)
              Text(
                '$recent ${recent == 1 ? 'contest' : 'contests'} completed '
                'or in progress in the last 30 days',
                key: ResultsPage.summaryText,
              ),
            const SizedBox(height: 16),
            ContestFilterBar(filters: filters, onChanged: _applyFilters),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              Text('Could not load contests: ${snapshot.error}')
            else if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (listed.isEmpty)
              const Text('No contests found.')
            else
              for (final contest in listed)
                ContestRow(contest: contest, onTap: () => _open(contest)),
          ],
        );
      },
    );
  }
}
