import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/configuration/draw_readiness.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest({
  LifecycleState state = LifecycleState.configuring,
  AdminLock lock = AdminLock.unlocked,
}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Open',
  startDateTime: DateTime.utc(2026, 10, 17),
  endDateTime: DateTime.utc(2026, 10, 18),
  timezone: 'America/Denver',
  lifecycleState: state,
  adminLock: lock,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

DrawReadiness _evaluate({
  Contest? contest,
  bool valid = true,
  int pilots = 2,
  bool drawn = false,
}) => DrawReadiness.evaluate(
  contest: contest ?? _contest(),
  hasValidConfiguration: valid,
  scoringPilots: pilots,
  matrixDrawn: drawn,
);

void main() {
  test('is enabled for a configuring contest with two pilots', () {
    expect(_evaluate().enabled, isTrue);
  });

  test('needs two scoring pilots', () {
    expect(_evaluate(pilots: 1).enabled, isFalse);
    expect(_evaluate(pilots: 0).reasons, hasLength(1));
  });

  test('needs a valid configuration', () {
    expect(_evaluate(valid: false).enabled, isFalse);
  });

  test('is blocked by a lock, completion and a created contest', () {
    expect(
      _evaluate(contest: _contest(lock: AdminLock.locked)).enabled,
      isFalse,
    );
    expect(
      _evaluate(contest: _contest(state: LifecycleState.completed)).enabled,
      isFalse,
    );
    expect(
      _evaluate(contest: _contest(state: LifecycleState.created)).reasons,
      ['Save the configuration first.'],
    );
  });

  test('is blocked once a matrix is drawn', () {
    expect(_evaluate(drawn: true).enabled, isFalse);
  });

  test('lists every reason', () {
    expect(
      _evaluate(valid: false, pilots: 0, drawn: true).reasons,
      hasLength(3),
    );
  });
}
