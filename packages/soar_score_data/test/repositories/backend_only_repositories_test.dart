import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

/// An installation has no backend-only tables, so the account repositories
/// answer `BackendOnlyError` there (the API maps it to 409 `backend_only`).
void main() {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(Backend.sqlite);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  final anyId = core.Id.create();
  final calls = <String, Future<Object?> Function(Repository r)>{
    'accounts': (r) => r.accountRepository.findById(anyId),
    'account identities': (r) =>
        r.accountIdentityRepository.listForAccount(anyId),
    'account public profiles': (r) =>
        r.accountPublicProfileRepository.findForAccount(anyId),
    'participant account links': (r) =>
        r.participantAccountLinkRepository.listForAccount(anyId),
    'participant directory entries': (r) =>
        r.participantDirectoryEntryRepository.listListed(),
  };

  for (final MapEntry(:key, :value) in calls.entries) {
    test('$key are not available on an installation', () async {
      await expectLater(
        value(repository),
        throwsA(isA<core.BackendOnlyError>()),
      );
    });
  }
}
