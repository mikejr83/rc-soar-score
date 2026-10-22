import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// Another installation's demo contest, imported into [database] for
/// inspection, as a person would after being sent the file.
///
/// Returns the imported contest and the inspection owner that owns it.
Future<({core.Contest contest, core.Id owner})> importDemoForInspection(
  SoarScoreDatabase database, {
  required core.Id localAccountId,
  String contestName = 'Autumn F5J Classic',
}) async {
  final source = createInMemoryDatabase();
  try {
    await SystemDataSeeder(source).seed();
    final sourceLocal = await LocalAccountRepository(source).ensure();
    await DemoDataSeeder(
      Repository(source),
      localAccountId: sourceLocal,
    ).seed();
    final contest = (await Repository(
      source,
    ).contestRepository.getAll()).firstWhere((c) => c.name == contestName);
    final file = ExchangeFile.decode(
      (await ContestExporter(source).export(contest.id)).encode(),
    );
    final result = await ContestImporter(database).import(
      file,
      mode: ImportMode.inspection,
      target: ImportTarget(localAccountId: localAccountId),
    );
    final imported = await ContestRepository(database).findById(contest.id);
    return (contest: imported!, owner: result.ownerId);
  } finally {
    await source.close();
  }
}
