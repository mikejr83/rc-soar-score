import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/contest_open_action.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest(LifecycleState state) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Open',
  startDateTime: DateTime.utc(2026, 10, 17),
  endDateTime: DateTime.utc(2026, 10, 18),
  timezone: 'America/Denver',
  lifecycleState: state,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

void main() {
  test('the action follows the lifecycle state', () {
    expect(
      ContestOpenAction.of(_contest(LifecycleState.created)).label,
      'Open',
    );
    expect(
      ContestOpenAction.of(_contest(LifecycleState.configuring)).label,
      'Open',
    );
    expect(
      ContestOpenAction.of(_contest(LifecycleState.ready)).label,
      'Continue',
    );
    expect(
      ContestOpenAction.of(_contest(LifecycleState.running)).label,
      'Continue',
    );
    expect(
      ContestOpenAction.of(_contest(LifecycleState.completed)).label,
      'View',
    );
  });

  test('new contests open to configuration, others to the workspace', () {
    final created = _contest(LifecycleState.created);
    final running = _contest(LifecycleState.running);
    final id = created.id.value;

    expect(contestOpenPath(created), contestConfigurationPath(id));
    expect(contestOpenPath(running), contestWorkspacePath(id));
    expect(
      contestOpenPath(_contest(LifecycleState.completed)),
      contestWorkspacePath(id),
    );
  });
}
