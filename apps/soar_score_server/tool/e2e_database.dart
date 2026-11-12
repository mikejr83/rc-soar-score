import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// The contest journey needs installation demo data and, when publishing is
/// enabled, the hosted server's tables too. This combined schema is test-only.
class E2eDatabase extends SoarScoreDatabase {
  E2eDatabase(
    super.executor, {
    required DatabaseProfile profile,
    required bool publishingEnabled,
  }) : _includeLocalTables =
           publishingEnabled && profile == DatabaseProfile.native,
       // Backend repositories also check the profile before allowing writes.
       super(profile: publishingEnabled ? DatabaseProfile.server : profile);

  final bool _includeLocalTables;

  @override
  List<TableInfo<Table, Object?>> get profileTables =>
      _includeLocalTables ? allTables.toList() : super.profileTables;
}

/// Seeds the same director for the API principal, demo ownership and publishing.
Future<core.Id> seedE2eDatabase(
  E2eDatabase database, {
  required bool serverProfile,
}) async {
  await SystemDataSeeder(database).seed();
  final repository = Repository(database);
  final director = serverProfile
      ? core.Id.create()
      : await LocalAccountRepository(database).ensure();
  if (database.profile == DatabaseProfile.server) {
    final now = DateTime.now().toUtc();
    await repository.accountRepository.save(
      core.Account(
        id: director,
        firstName: 'Dana',
        lastName: 'Director',
        kind: core.AccountKind.registered,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  if (!serverProfile) {
    await DemoDataSeeder(repository, localAccountId: director).seed();
  }
  return director;
}
