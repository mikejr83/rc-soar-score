import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  // Only an installation has the table; the server keeps accounts itself.
  final skip = backend == Backend.postgres
      ? 'client-only table, not on the server'
      : false;

  late Installation inst;
  late LocalAccountRepository accounts;

  setUp(() async {
    inst = await Installation.open(backend);
    accounts = LocalAccountRepository(inst.db);
  });
  tearDown(() => inst.close());

  test('finds nothing before the first run', skip: skip, () async {
    expect(await accounts.find(), isNull);
  });

  test('creates one UUIDv7 id on first run and keeps it', skip: skip, () async {
    final id = await accounts.ensure();

    expect(core.Id.parse(id.value), id);
    expect(await accounts.find(), id);
    expect(await inst.count('local_account'), 1);
  });

  test('never regenerates the id', skip: skip, () async {
    final id = await accounts.ensure();

    expect(await accounts.ensure(), id);
    expect(await LocalAccountRepository(inst.db).ensure(), id);
    expect(await inst.count('local_account'), 1);
  });

  test('is one row however many calls race', skip: skip, () async {
    final ids = await Future.wait([
      for (var i = 0; i < 5; i++) accounts.ensure(),
    ]);

    expect(ids.toSet(), hasLength(1));
    expect(await inst.count('local_account'), 1);
  });
}
