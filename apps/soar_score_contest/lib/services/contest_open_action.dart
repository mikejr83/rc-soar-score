import 'package:soar_score_core/soar_score_core.dart';

import '../router.dart';

/// What the primary action on a contest does, by lifecycle state
/// (`plan/ui/contest-administration/main-page.md`): `Open` takes a new
/// contest to its configuration, `Continue` returns to a contest that is
/// under way, and `View` looks at a finished one.
enum ContestOpenAction {
  open('Open'),
  continueContest('Continue'),
  view('View');

  const ContestOpenAction(this.label);

  final String label;

  static ContestOpenAction of(Contest contest) =>
      switch (contest.lifecycleState) {
        LifecycleState.created || LifecycleState.configuring => open,
        LifecycleState.ready || LifecycleState.running => continueContest,
        LifecycleState.completed => view,
      };
}

/// The route the primary action on [contest] opens.
///
/// A completed contest opens the workspace, which is read-only for it.
String contestOpenPath(Contest contest) {
  final id = contest.id.value;
  return switch (ContestOpenAction.of(contest)) {
    ContestOpenAction.open => contestConfigurationPath(id),
    ContestOpenAction.continueContest ||
    ContestOpenAction.view => contestWorkspacePath(id),
  };
}
