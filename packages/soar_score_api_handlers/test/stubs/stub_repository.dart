import 'package:soar_score_core/soar_score_core.dart' as core;

import 'stub_configuration_repositories.dart';
import 'stub_contest_repository.dart';

/// A repository with only the contracts the handlers under test use: the
/// contests, and (for configuration) its revisions, the system discipline
/// profiles and the system landing tables.
class StubRepository implements core.Repository {
  StubRepository(this._contestRepository)
    : configurations = StubConfigurationRevisionRepository(
        _contestRepository is StubContestRepository
            ? _contestRepository
            : StubContestRepository(),
      );

  @override
  core.ContestRepository get contestRepository => _contestRepository;

  final core.ContestRepository _contestRepository;

  /// The stored configuration revisions, for tests to inspect.
  final StubConfigurationRevisionRepository configurations;

  @override
  core.ContestConfigurationRevisionRepository
  get contestConfigurationRevisionRepository => configurations;

  @override
  core.DisciplineProfileRepository get disciplineProfileRepository =>
      StubDisciplineProfileRepository();

  @override
  core.LandingTableRepository get landingTableRepository =>
      StubLandingTableRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
