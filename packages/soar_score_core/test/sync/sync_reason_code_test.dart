import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('SyncReasonCode', () {
    test('wire codes are unique', () {
      final codes = SyncReasonCode.values.map((r) => r.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
    });

    test('tryParse round-trips every code', () {
      for (final reason in SyncReasonCode.values) {
        expect(SyncReasonCode.tryParse(reason.code), reason);
      }
    });

    test('tryParse returns null for an unknown or missing code', () {
      expect(SyncReasonCode.tryParse('from_the_future'), isNull);
      expect(SyncReasonCode.tryParse(null), isNull);
    });

    test('covers the codes named in the data model documents', () {
      final documented = {
        'stale_base',
        'inactive_installation',
        'unknown_matrix_revision',
        'unknown_flight_group',
        'entity_deleted',
        'unique_violation',
        'locked',
        'unauthorized',
        'config_revision_conflict',
        'unsupported_protocol_version',
        'schema_too_old',
        'director_over_participant',
        'scored_assignment',
      };
      final known = SyncReasonCode.values.map((r) => r.code).toSet();
      expect(known.containsAll(documented), isTrue);
    });
  });

  test('the build speaks a protocol it accepts', () {
    expect(
      SyncProtocol.protocolVersion,
      greaterThanOrEqualTo(SyncProtocol.minProtocolVersion),
    );
  });
}
