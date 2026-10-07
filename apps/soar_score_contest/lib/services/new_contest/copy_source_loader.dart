import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'copy_source.dart';
import 'wizard_discipline.dart';

/// Loads what the wizard can copy from [contest]: its latest configuration
/// (if it has one) and its pilots with their class.
///
/// Only pilots are copied, so non-flying participations are left out.
Future<CopySource> loadCopySource(ApiClient client, Contest contest) async {
  ContestConfigurationRevision? configuration;
  try {
    configuration = await client.configuration(contest.id);
  } on ApiHttpError catch (error) {
    // A contest that was never configured has nothing but pilots to copy.
    if (error.statusCode != 404) {
      rethrow;
    }
  }
  final participations = await client.participations(contest.id);
  final pilots = participations
      .where((participation) => participation.roleType == RoleType.pilot)
      .toList();
  final names = <Id, String>{};
  if (pilots.isNotEmpty) {
    for (final profile in await client.participants()) {
      names[profile.id] = '${profile.firstName} ${profile.lastName}';
    }
  }
  return CopySource(
    contest: contest,
    discipline: configuration == null
        ? null
        : WizardDiscipline.forProfile(configuration.disciplineProfileId),
    options: configuration == null
        ? null
        : CoreOptions.fromMap(configuration.config.core),
    pilots: [
      for (final pilot in pilots)
        SourcePilot(
          profileId: pilot.participantProfileId,
          name: names[pilot.participantProfileId] ?? 'Unknown pilot',
          classification: pilot.classification,
        ),
    ],
  );
}
