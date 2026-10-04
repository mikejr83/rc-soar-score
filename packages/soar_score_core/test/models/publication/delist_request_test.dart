import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

DelistRequest make({
  DelistState state = DelistState.pending,
  Id? by,
  DateTime? at,
  String? note,
}) => DelistRequest(
  id: exampleId(1),
  publicationId: exampleId(2),
  requestedBy: exampleId(3),
  trigger: DelistTrigger.ownerRequest,
  requestedAt: t0,
  state: state,
  decidedBy: by,
  decidedAt: at,
  decisionNote: note,
);

void main() {
  group('DelistRequest', () {
    test('round trips with documented enum text', () {
      final r = make();
      expect(r.isPending, isTrue);
      expect(r.toJson()['trigger'], 'owner_request');
      expect(r.toJson()['state'], 'pending');
      expect(DelistRequest.fromJson(r.toJson()), r);
      expect(r, isA<BackendOnly>());
    });

    test('trigger and state values use their documented text', () {
      final json = make().toJson()..['trigger'] = 'account_closure';
      expect(
        DelistRequest.fromJson(json).trigger,
        DelistTrigger.accountClosure,
      );
      expect(make(state: DelistState.withdrawn).toJson()['state'], 'withdrawn');
    });

    test('a decision records who, when and why together', () {
      final ok = make(
        state: DelistState.approved,
        by: exampleId(4),
        at: t0,
        note: 'Owner is leaving the platform',
      );
      expect(ok.isPending, isFalse);
      expect(DelistRequest.fromJson(ok.toJson()), ok);
      expect(
        () => make(state: DelistState.denied, by: exampleId(4), at: t0),
        throwsArgumentError,
      );
      expect(() => make(state: DelistState.approved), throwsArgumentError);
    });

    test('a blank decision note is not a rationale', () {
      expect(
        () => make(
          state: DelistState.denied,
          by: exampleId(4),
          at: t0,
          note: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('only a decided request has decision fields', () {
      expect(
        () => make(by: exampleId(4), at: t0, note: 'x'),
        throwsArgumentError,
      );
      expect(
        () => make(state: DelistState.withdrawn, note: 'x'),
        throwsArgumentError,
      );
    });
  });
}
