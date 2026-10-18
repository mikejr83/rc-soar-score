import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api_client_provider.dart';
import '../../contest_routes.dart';
import '../../models/results/contest_load_result.dart';
import '../../models/results/contest_view.dart';
import '../../models/results/published_contest.dart';
import '../../widgets/results/contest_header_card.dart';
import '../../widgets/results/flight_group_table.dart';
import '../../widgets/results/overall_results_table.dart';
import '../../widgets/results/round_selector.dart';
import '../../widgets/results/team_results_table.dart';
import 'contest_not_found_page.dart';
import 'contest_not_visible_page.dart';

/// A published contest's [view] as of [round], or the latest round with
/// scores when null (plan/ui/public-site/view-contest.md).
///
/// [loader] defaults to the API client from the tree; tests pass fake data.
class ContestPage extends StatefulWidget {
  const ContestPage({
    super.key,
    required this.contestId,
    this.view = ContestView.overall,
    this.round,
    this.pilotKey,
    this.loader,
  });

  final String contestId;
  final ContestView view;
  final int? round;

  /// The pilot the flight groups view scrolls to.
  final String? pilotKey;
  final PublicationLoader? loader;

  static const Key retryKey = Key('contest_page_retry');
  static const Key overallLinkKey = Key('contest_page_overall_link');
  static const Key teamsLinkKey = Key('contest_page_teams_link');
  static const Key flightGroupsLinkKey = Key('contest_page_groups_link');

  /// Disciplines whose flights carry a landing score; F5J has a landing
  /// bonus, F3K does not.
  static bool disciplineHasLanding(String disciplineType) =>
      const {'F5J', 'F3J', 'ALES', 'ThermalDuration'}.contains(disciplineType);

  @override
  State<ContestPage> createState() => _ContestPageState();
}

class _ContestPageState extends State<ContestPage> {
  ContestLoadResult? _result;
  final _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(ContestPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
      _load();
    } else if (oldWidget.pilotKey != widget.pilotKey ||
        oldWidget.round != widget.round ||
        oldWidget.view != widget.view) {
      _afterFrame();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _result = null);
    final loader = widget.loader ?? context.apiClient.publicPublication;
    final result = await ContestLoadResult.load(loader, widget.contestId);
    if (!mounted) return;
    setState(() => _result = result);
    _afterFrame();
  }

  /// Once the view is laid out: leave a team-less team view, or scroll to
  /// the clicked pilot's flight.
  void _afterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_result case ContestLoaded(:final results)
          when widget.view == ContestView.teams && !results.hasTeams) {
        context.replace(
          contestResultsPath(widget.contestId, round: widget.round),
        );
        return;
      }
      if (_highlightKey.currentContext case final target?) {
        Scrollable.ensureVisible(target, duration: Duration.zero);
      }
    });
  }

  String _path(
    ContestView view,
    int? round, {
    String? pilotKey,
  }) => switch (view) {
    ContestView.overall => contestResultsPath(widget.contestId, round: round),
    ContestView.teams => contestTeamResultsPath(widget.contestId, round: round),
    ContestView.flightGroups => contestFlightGroupsPath(
      widget.contestId,
      round!,
      pilotKey: pilotKey,
    ),
  };

  void _goToRound(int round) => context.go(_path(widget.view, round));

  void _goToFlightGroups(int round, String? pilotKey) =>
      context.go(_path(ContestView.flightGroups, round, pilotKey: pilotKey));

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
    final view = widget.view;
    if (view == ContestView.teams && !results.hasTeams) {
      // _afterFrame replaces the route.
      return const Center(child: CircularProgressIndicator());
    }
    final round = widget.round ?? results.latestRound;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContestHeaderCard(header: results.header),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  view.title,
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
          Wrap(
            spacing: 8,
            children: [
              if (view != ContestView.overall)
                TextButton(
                  key: ContestPage.overallLinkKey,
                  onPressed: () =>
                      context.go(_path(ContestView.overall, widget.round)),
                  child: const Text('Overall results'),
                ),
              if (view == ContestView.overall && results.hasTeams)
                TextButton(
                  key: ContestPage.teamsLinkKey,
                  onPressed: () =>
                      context.go(_path(ContestView.teams, widget.round)),
                  child: const Text('Team results'),
                ),
              if (view == ContestView.overall && round != null)
                TextButton(
                  key: ContestPage.flightGroupsLinkKey,
                  onPressed: () => _goToFlightGroups(round, null),
                  child: Text('Flight groups of round $round'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (round == null)
            const Text('No results have been published for this contest yet.')
          else
            _body(results, view, round),
        ],
      ),
    );
  }

  Widget _body(PublishedContest results, ContestView view, int round) {
    switch (view) {
      case ContestView.overall:
        final rows = results.rowsAsOf(round);
        if (rows.isEmpty) return Text('There are no results for round $round.');
        return OverallResultsTable(
          rows: rows,
          round: round,
          onRoundTap: _goToFlightGroups,
        );
      case ContestView.teams:
        final teams = results.teamRowsAsOf(round);
        if (teams.isEmpty) {
          return Text('There are no team results for round $round.');
        }
        return TeamResultsTable(
          teams: teams,
          round: round,
          onRoundTap: _goToFlightGroups,
        );
      case ContestView.flightGroups:
        final groups = results.flightGroupsOf(round);
        if (groups.isEmpty) {
          return Text('There are no flights for round $round.');
        }
        final hasLanding = ContestPage.disciplineHasLanding(
          results.disciplineType,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final group in groups) ...[
              FlightGroupTable(
                group: group,
                hasLanding: hasLanding,
                highlightPilotKey: widget.pilotKey,
                highlightKey: _highlightKey,
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
    }
  }
}
