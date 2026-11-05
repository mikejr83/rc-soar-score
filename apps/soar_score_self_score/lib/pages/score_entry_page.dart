import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_scope.dart';
import '../models/entry_context.dart';
import '../router.dart';
import '../widgets/entry/score_entry_form.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';

/// F5J score entry for one flight: loads the flight's draw and the contest's
/// landing table, then shows the form.
class ScoreEntryPage extends StatelessWidget {
  const ScoreEntryPage({
    required this.contestId,
    required this.pilotId,
    required this.roundId,
    super.key,
  });

  final String contestId;
  final String pilotId;
  final String roundId;

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    final round = int.tryParse(roundId) ?? 0;
    void goToRound(int target) =>
        context.go(scoreEntryPath(contestId, pilotId, '$target'));
    return LoadableScaffold<EntryContext>(
      load: () => repository.entryContext(contestId, pilotId, round),
      reloadKey: (repository, contestId, pilotId, roundId),
      appBar: (context, data) => SelfScoreAppBar(
        title: data == null
            ? 'Score entry'
            : data.pilotNumber == null
            ? data.pilotName
            : '${data.pilotName}, pilot ${data.pilotNumber}',
        contextLine: data == null
            ? null
            : [
                'Round ${data.round}',
                'Group ${data.group}',
                if (data.lane != null) 'Lane ${data.lane}',
              ].join(' · '),
        onBack: () => context.go(pilotPath(contestId, pilotId)),
        backLabel: 'Back to pilot overview',
        actions: data == null
            ? const []
            : [
                IconButton(
                  tooltip: 'Previous round',
                  onPressed: data.round > 1
                      ? () => goToRound(data.round - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next round',
                  onPressed: data.round < data.roundCount
                      ? () => goToRound(data.round + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
        showAccount: false,
      ),
      // The form keeps its own state, so a new flight gets a new form.
      builder: (context, data) => ScoreEntryForm(
        key: ValueKey((contestId, pilotId, roundId)),
        contestId: contestId,
        pilotId: pilotId,
        data: data,
      ),
    );
  }
}
