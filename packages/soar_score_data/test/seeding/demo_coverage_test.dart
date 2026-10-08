import 'dart:io';

import 'package:test/test.dart';

/// Keeps the demo data current: every repository on the `Repository`
/// contract is either filled by the demo seeder or listed here with the
/// reason it is not. A new repository fails this test until one of the two
/// is done, so adding a model means deciding what the demo shows for it.
///
/// Covered repositories are found by name in the demo seeding sources, so
/// the seeder must reach each one directly or through a service.
void main() {
  /// Repositories the demo does not fill, with why, and the issue that
  /// brings them in.
  const exempt = <String, String>{
    'publicationIdentityRepository': 'backend-only; needs a server demo (#291)',
    'publicationProjectionRepository':
        'backend-only; needs a server demo (#291)',
    'publicationParticipantRepository':
        'backend-only; needs a server demo (#291)',
    'delistRequestRepository': 'backend-only; needs a server demo (#291)',
  };

  /// Repositories the demo fills through a service rather than by name.
  const throughServices = <String>{
    'contestConfigurationRevisionRepository',
    'roleRepository',
    'landingTableRepository',
    'disciplineProfileRepository',
    'roundRepository',
    'roundGroupRepository',
    'matrixRevisionRepository',
    'matrixAssignmentRepository',
    'scorePlaceholderRepository',
    'scoreAttemptRepository',
    'officialScoreRepository',
    'flightResultRepository',
    'participationStandingRepository',
    'teamStandingRepository',
    'teamRepository',
    'teamMembershipRepository',
    'contestParticipationRepository',
  };

  test('every repository is seeded or exempt', () {
    final contract = File('../soar_score_core/lib/repositories/repository.dart')
        .readAsStringSync();
    final getters = RegExp(
      r'^\s+\w+Repository\s+get\s+(\w+Repository);',
      multiLine: true,
    ).allMatches(contract).map((m) => m.group(1)!).toSet();
    // A getter wrapped over two lines does not match the pattern above.
    getters.addAll(
      RegExp(
        r'get\s+(\w+Repository);',
        multiLine: true,
      ).allMatches(contract).map((m) => m.group(1)!),
    );
    expect(getters, isNotEmpty);

    final sources = Directory('lib/seeding/demo')
        .listSync()
        .whereType<File>()
        .map((f) => f.readAsStringSync())
        .join('\n');
    final unknown = [
      for (final name in getters)
        if (!exempt.containsKey(name) &&
            !throughServices.contains(name) &&
            !sources.contains(name))
          name,
    ];
    expect(
      unknown,
      isEmpty,
      reason:
          'Seed these in the demo data or add them to the exemptions in '
          'demo_coverage_test.dart with the reason and the issue.',
    );
  });

  test('exemptions name repositories that still exist', () {
    final contract = File('../soar_score_core/lib/repositories/repository.dart')
        .readAsStringSync();
    for (final name in [...exempt.keys, ...throughServices]) {
      expect(contract, contains(name), reason: '$name was removed');
    }
  });
}
