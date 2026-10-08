import 'package:soar_score_api/soar_score_api.dart';
import 'package:test/test.dart';

void main() {
  const request = EnterScoreRequest(
    clientMutationId: 'entry-1',
    baseScoreRevision: 1,
    components: {'time_flown': 540, 'launch_height': 200},
    reason: 'Timer misread',
  );

  test('encodes snake_case keys', () {
    expect(request.toJson(), {
      'client_mutation_id': 'entry-1',
      'base_score_revision': 1,
      'components': {'time_flown': 540, 'launch_height': 200},
      'reason': 'Timer misread',
    });
  });

  test('round-trips and the reason is optional', () {
    final decoded = EnterScoreRequest.fromJson({
      'client_mutation_id': 'entry-1',
      'base_score_revision': 0,
      'components': {'motor_restart': true},
    });

    expect(decoded.clientMutationId, 'entry-1');
    expect(decoded.baseScoreRevision, 0);
    expect(decoded.components, {'motor_restart': true});
    expect(decoded.reason, isNull);
    expect(
      EnterScoreRequest.fromJson(request.toJson()).reason,
      'Timer misread',
    );
  });

  test('a missing client mutation id fails to decode', () {
    expect(
      () => EnterScoreRequest.fromJson({
        'base_score_revision': 0,
        'components': <String, Object?>{},
      }),
      throwsA(anything),
    );
  });
}
