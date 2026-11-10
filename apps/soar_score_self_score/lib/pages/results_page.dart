import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_scope.dart';
import '../models/results_view.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/results_body.dart';
import '../widgets/self_score_app_bar.dart';

/// Where the pilot stands as of a round. [asOfRound] null means the latest
/// round; an earlier round shows a banner with a way back to the latest.
class ResultsPage extends StatelessWidget {
  const ResultsPage({required this.contestId, this.asOfRound, super.key});

  final String contestId;
  final int? asOfRound;

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    return LoadableScaffold<ResultsView>(
      allowRefresh: true,
      load: () => repository.results(contestId, asOfRound: asOfRound),
      reloadKey: (repository, contestId, asOfRound),
      appBar: (context, data) => SelfScoreAppBar(
        title: 'Results',
        contextLine: data?.contestName,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(teamPath(contestId)),
        backLabel: 'Back',
        actions: const [ConnectionIndicator()],
        showAccount: false,
      ),
      builder: (context, data) => ResultsBody(contestId: contestId, data: data),
    );
  }
}
