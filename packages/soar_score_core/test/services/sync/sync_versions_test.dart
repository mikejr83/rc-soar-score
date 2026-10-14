import 'package:soar_score_core/errors/sync_refusal.dart';
import 'package:soar_score_core/services/sync/sync_versions.dart';
import 'package:test/test.dart';

void main() {
  const versions = SyncVersions(minSchemaVersion: 2, maxSchemaVersion: 3);

  Matcher refusal(String code, int status) => throwsA(
    isA<SyncRefusal>()
        .having((e) => e.code, 'code', code)
        .having((e) => e.statusCode, 'status', status),
  );

  test('versions inside the range pass', () {
    versions.require(
      protocolVersion: versions.protocolVersion,
      schemaVersion: 3,
    );
  });

  test('a protocol out of range is a 426', () {
    expect(
      () => versions.require(
        protocolVersion: versions.protocolVersion + 1,
        schemaVersion: 2,
      ),
      refusal('unsupported_protocol_version', 426),
    );
  });

  test('a schema below the minimum is a 426', () {
    expect(
      () => versions.require(
        protocolVersion: versions.protocolVersion,
        schemaVersion: 1,
      ),
      refusal('schema_too_old', 426),
    );
  });

  test('a schema above the maximum is a 409', () {
    expect(
      () => versions.require(
        protocolVersion: versions.protocolVersion,
        schemaVersion: 4,
      ),
      refusal('unsupported_protocol_version', 409),
    );
  });

  test('exactly accepts one schema version only', () {
    const one = SyncVersions.exactly(1);

    expect(one.minSchemaVersion, one.maxSchemaVersion);
  });
}
