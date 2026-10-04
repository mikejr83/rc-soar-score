import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

InstallationActivation make({DateTime? endedAt}) => InstallationActivation(
  id: exampleId(0xc1),
  contestId: exampleId(0x10),
  installationId: exampleId(0xc0),
  activatedBy: exampleId(1),
  kind: ActivationKind.initial,
  activatedAt: t0,
  endedAt: endedAt,
);

void main() {
  group('InstallationActivation', () {
    test('round trips through JSON', () {
      final json = make().toJson();
      expect(json['kind'], 'Initial');
      expect(json['ended_at'], isNull);
      expect(InstallationActivation.fromJson(json), make());
    });

    test('is open until closed, and close returns a copy', () {
      final open = make();
      final closed = open.close(t0.add(const Duration(hours: 1)));
      expect(open.isOpen, isTrue);
      expect(closed.isOpen, isFalse);
      expect(closed.id, open.id);
      expect(closed.endedAt, t0.add(const Duration(hours: 1)));
    });

    test('cannot be closed twice', () {
      final closed = make().close(t0);
      expect(() => closed.close(t0), throwsStateError);
    });

    test('rejects an end before the start', () {
      expect(
        () => make(endedAt: t0.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    test('kind values match the documents', () {
      for (final (kind, text) in [
        (ActivationKind.initial, 'Initial'),
        (ActivationKind.replacement, 'Replacement'),
        (ActivationKind.reclaim, 'Reclaim'),
      ]) {
        final json = {...make().toJson(), 'kind': text};
        expect(InstallationActivation.fromJson(json).kind, kind);
      }
    });

    test('is backend only', () {
      expect(make(), isA<BackendOnly>());
    });
  });
}
