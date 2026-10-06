import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final profileId = Id.parse('019c0000-0000-7000-8000-000000000030');
  final tableId = Id.parse('019c0000-0000-7000-8000-000000000031');

  final request = SaveConfigurationRequest(
    baseRevisionNumber: 2,
    disciplineProfileId: profileId,
    config: ContestConfig(
      core: {'teams_enabled': true},
      discipline: {'flight_window_minutes': 10},
    ),
    landingTableId: tableId,
    notes: 'second pass',
  );

  test('encodes snake_case keys with the config split in two maps', () {
    expect(request.toJson(), {
      'base_revision_number': 2,
      'discipline_profile_id': profileId.value,
      'config': {
        'core': {'teams_enabled': true},
        'discipline': {'flight_window_minutes': 10},
      },
      'landing_table_id': tableId.value,
      'notes': 'second pass',
    });
  });

  test('round-trips', () {
    final decoded = SaveConfigurationRequest.fromJson(request.toJson());

    expect(decoded.baseRevisionNumber, 2);
    expect(decoded.disciplineProfileId, profileId);
    expect(decoded.config, request.config);
    expect(decoded.landingTableId, tableId);
    expect(decoded.notes, 'second pass');
  });

  test('landing table and notes are optional', () {
    final decoded = SaveConfigurationRequest.fromJson({
      'base_revision_number': 0,
      'discipline_profile_id': profileId.value,
      'config': {
        'core': <String, Object?>{},
        'discipline': <String, Object?>{},
      },
    });

    expect(decoded.landingTableId, isNull);
    expect(decoded.notes, isNull);
  });

  test('a missing base revision number fails to decode', () {
    expect(
      () => SaveConfigurationRequest.fromJson({
        'discipline_profile_id': profileId.value,
        'config': {
          'core': <String, Object?>{},
          'discipline': <String, Object?>{},
        },
      }),
      throwsA(anything),
    );
  });
}
