import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api_client_provider.dart';
import '../../contest_routes.dart';
import '../../models/results/contest_load_result.dart';
import '../../models/results/published_contest.dart';
import '../../models/results/pilot_standing_row.dart';
import '../../widgets/results/contest_header_card.dart';
import '../../widgets/results/overall_results_table.dart';
import '../../widgets/results/round_selector.dart';
import 'contest_not_found_page.dart';
import 'contest_not_visible_page.dart';

/// A published contest's Overall Individual Results as of [round], or the
/// latest round with scores when null (plan/ui/public-site/view-contest.md).
///
/// [loader] defaults to the API client from the tree; tests pass fake data.
class ContestPage extends StatefulWidget {
  const ContestPage({
    super.key,
    required this.contestId,
    this.round,
    this.loader,
  });

  final String contestId;
  final int? round;
  final PublicationLoader? loader;

  static const Key retryKey = Key('contest_page_retry');

  @override
  State<ContestPage> createState() => _ContestPageState();
}

class _ContestPageState extends State<ContestPage> {
  ContestLoadResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(ContestPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _result = null);
    final loader = widget.loader ?? context.apiClient.publicPublication;
    final result = await ContestLoadResult.load(loader, widget.contestId);
    if (mounted) setState(() => _result = result);
  }

  void _goToRound(int round) =>
      context.go(contestResultsPath(widget.contestId, round: round));

  @override
  Widget build(BuildContext context) {
    return switch (_result) {
      null => const Center(child: CircularProgressIndicator()),
      ContestNotFound() => const ContestNotFoundPage(),
      ContestNotVisible() => ContestNotVisiblePage(onRecheck: _load),
      ContestLoadFailed(:final message) => _failed(message),
      ContestLoaded(:final results) => _loaded(results),
    };
  }

  Widget _failed(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('The contest could not be loaded: $message'),
        const SizedBox(height: 12),
        FilledButton(
          key: ContestPage.retryKey,
          onPressed: _load,
          child: const Text('Try again'),
        ),
      ],
    ),
  );

  Widget _loaded(PublishedContest results) {
    final round = widget.round ?? results.latestRound;
    final rows = round == null ? <PilotStandingRow>[] : results.rowsAsOf(round);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContestHeaderCard(header: results.header),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Overall Individual Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RoundSelector(
              rounds: results.rounds,
              selected: round,
              onChanged: _goToRound,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (round == null)
          const Text('No results have been published for this contest yet.')
        else if (rows.isEmpty)
          Text('There are no results for round $round.')
        else
          OverallResultsTable(rows: rows, round: round),
      ],
    );
  }
}
